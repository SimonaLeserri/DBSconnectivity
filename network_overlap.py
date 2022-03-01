import argparse
import matplotlib.pyplot as plt
from my_tools import *
from matplotlib import rcParams
rcParams.update({'font.size': 17})

def compute_overlap(VTA_tracts, VTA_tracts_path, total_weights, sorted_codes):
    overlap = {}
    # for each VTA
    for VTA in VTA_tracts:
        overlap[VTA] = {}
        # read the file created in anhedonia_network.sh
        name = 'Bilateral_{v}_overlap_weights.csv'.format(v=VTA)
        size = os.path.getsize(os.path.join(VTA_tracts_path, VTA, name))
        # if the VTa includes at least one AN streamline
        if size != 0:
            # read the weights of the recruited AN streamlines
            sum_overlap = pd.read_csv(os.path.join(VTA_tracts_path, VTA, name), header=None, sep=' ',
                                      dtype=np.float64).sum(axis=1).item()
            # compute and save the % of AN activated by DBS
            percentage_overlap = round((sum_overlap / total_weights) * 100, 2)
            overlap[VTA] = percentage_overlap
        else:
            percentage_overlap = np.nan
            overlap[VTA] = percentage_overlap

    overlap_df = pd.DataFrame({session_code: overlap[VTA_code] for session_code, VTA_code in
                               enumerate(sorted_codes)}.values())
    overlap_df.columns = ['Percentage_overlap']
    return overlap_df  # a df with as many rows as there are sessions, column with % overlap AN &DBS


def plot_overlap(overlap, measures_df, destination_folder, dates):
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)
    for unique_measure in measures_df.measure.unique():
        if unique_measure == 'SHAPS':  # is the Anhedonia measure
            little_df = measures_df[measures_df.measure == unique_measure].reset_index()
            fig, ax = plt.subplots(figsize=(15, 8))
            plt.title('Reward network recruitment vs {} assessment'.format(unique_measure))

            # using the twinx() for creating another
            # axes object for secondary y-Axis
            ax2 = ax.twinx()
            plot_1 = ax.plot(overlap.index, overlap.Percentage_overlap, label='Structural connectivity', linestyle='--',
                             color='g')
            ax.set_xticks(overlap.index, dates, rotation=90)
            ax.set_ylim([0, 100])
            # giving labels to the axes
            ax.set_xlabel('session')
            ax.xaxis.labelpad = 20
            ax.set_ylabel('% of Anhedonia network recruited - weights', color='g')

            ax2.set_ylim([0, 101])
            plot_2 = ax2.plot(little_df.index, little_df.value, label='Anhedonia scale', color='b')
            # secondary y-axis label
            ax2.set_ylabel('% of {} scale'.format(unique_measure), color='b')

            # add legends
            lns = plot_1 + plot_2
            labels = [l.get_label() for l in lns]
            plt.legend(lns, labels)

            # defining display layout
            plt.show()
            plt.savefig(os.path.join(destination_folder, 'AN_overlap_{}_FINAL'.format(unique_measure)), bbox_inches="tight")
    return

def main(args):
    AN = os.path.join(args.patient_path, 'DWI', 'tractography', 'Bilateral_AN_weights.csv')

    total_weights = pd.read_csv(AN, header=None, sep=' ', dtype=np.float64).sum(axis=1).item()

    VTA_tracts_path = os.path.join(args.patient_path, 'VTA_tracts')
    VTA_tracts = sorted([el for el in os.listdir(VTA_tracts_path) if el.startswith('VTA')])

    sorted_codes = np.load(os.path.join(args.plot_path, 'sorted_code_list.npy'), allow_pickle=True)
    sorted_codes = ['VTA_{0:0=2d}'.format(code) for code in sorted_codes]

    dates = np.load(args.plot_path + '/sorted_dates.npy')

    overlap_df = compute_overlap(VTA_tracts, VTA_tracts_path, total_weights, sorted_codes)
    df = read_assessments(dates, args.assessment_path, args.baseline_file, args.files_to_remove)
    plot_overlap(overlap_df, df, args.save_path, dates)
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Plotting % of fibers belonging to the Anhedonia network and recruited by DBS stimulation')
    parser.add_argument('--patient_path',type=str,help='Complete path to patient VTA')
    parser.add_argument('--assessment_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--files_to_remove', nargs='*', help='Are there files not to consider?') #give as string '' * means zero or more
    parser.add_argument('--baseline_file', type=str, help='the file.xlsm, sotred in assessment_path, describing the baseline')
    parser.add_argument('--plot_path', type=str, help='where the sorted code list is stored ')
    parser.add_argument('--save_path', type=str, help='where to store resulting video')

    args = parser.parse_args()
    main(args)