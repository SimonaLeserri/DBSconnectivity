import argparse
import matplotlib.pyplot as plt
from my_tools import *

def compute_overlap(VTA_tracts, VTA_tracts_path,total_weights,sorted_codes):
    overlap = {}
    for VTA in VTA_tracts:
        overlap[VTA] = {}
        for side in ['Right', 'Left']:
            name = '{s}_{v}_overlap_weights.csv'.format(s=side, v=VTA)
            size = os.path.getsize(os.path.join(VTA_tracts_path, VTA, name))
            if size != 0:
                sum_overlap = pd.read_csv(os.path.join(VTA_tracts_path, VTA, name), header=None, sep=' ',
                                          dtype=np.float64).sum(axis=1).item()
                percentage_overlap = round((sum_overlap / total_weights[side]) * 100, 2)
                overlap[VTA][side] = percentage_overlap
            else:
                percentage_overlap = np.nan
                overlap[VTA][side] = percentage_overlap

    session_overlap_right_dict = {session_code: overlap[VTA_code]['Right'] for session_code, VTA_code in
                                  enumerate(sorted_codes)}
    session_overlap_left_dict = {session_code: overlap[VTA_code]['Left'] for session_code, VTA_code in
                                 enumerate(sorted_codes)}
    overlap_df = pd.DataFrame(zip(session_overlap_right_dict.values(), session_overlap_left_dict.values()),
                              columns=['Right', 'Left'])
    return overlap_df #a df with as many rows as there are sessions, column right and left with % overlap AN &DBS

def plot_overlap(overlap, measures_df, destination_folder):
    print(destination_folder)
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)
    for unique_measure in measures_df.measure.unique():
        little_df=measures_df[measures_df.measure == unique_measure].reset_index()
        fig, ax = plt.subplots(figsize=(10, 5))
        plt.title('anhedonia network recruitment vs {} assessment'.format(unique_measure))

        # using the twinx() for creating another
        # axes object for secondary y-Axis
        ax2 = ax.twinx()
        ax.plot(overlap.index, overlap['Right'], label='Right Connectivity', linestyle='--', color='g')
        ax.plot(overlap.index, overlap['Left'], label='Left Connectivity', color='g')
        ax.set_ylim([0, 100])
        ax2.set_ylim([0, 100])
        ax2.plot(little_df.index, little_df.value, label='Anhedonia scale', color='b')

        # giving labels to the axes
        ax.set_xlabel('session')
        ax.set_ylabel('% of Anhedonia network recruited - weights', color='g')

        # secondary y-axis label
        ax2.set_ylabel('% of {} scale'.format(unique_measure), color='b')
        plt.legend()
        # defining display layout
        plt.show()
        plt.savefig(os.path.join(destination_folder, 'An_{}'.format(unique_measure)),bbox_inches="tight")
    return

def main(args):
    AN_right = os.path.join(args.patient_path, 'DWI', 'tractography', 'Right_AN_weights.csv')
    AN_left = os.path.join(args.patient_path, 'DWI', 'tractography', 'Left_AN_weights.csv')

    total_weights = {}
    total_weights['Right'] = pd.read_csv(AN_right, header=None, sep=' ', dtype=np.float64).sum(axis=1).item()
    total_weights['Left'] = pd.read_csv(AN_left, header=None, sep=' ', dtype=np.float64).sum(axis=1).item()
    VTA_tracts_path = os.path.join(args.patient_path, 'VTA_tracts')
    VTA_tracts = sorted([el for el in os.listdir(VTA_tracts_path) if el.startswith('VTA')])

    sorted_codes = np.load(os.path.join(args.plot_path, 'sorted_code_list.npy'), allow_pickle=True)
    sorted_codes = ['VTA_{0:0=2d}'.format(code) for code in sorted_codes]
    overlap_df = compute_overlap(VTA_tracts, VTA_tracts_path, total_weights, sorted_codes)
    #############

    dates = np.load(args.plot_path + '/sorted_dates.npy')
    # the .npy files has the dates in the format "%d/%m/%Y"
    # while the original excel assessment files follow "%d.%m.%Y"

    df = read_assessments(dates, args.assessment_path, args.baseline_file, args.files_to_remove)
    plot_overlap(overlap_df, df, args.save_path)
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Plotting the MDD measurments evolution')
    parser.add_argument('--patient_path',type=str,help='Complete path to patient VTA')
    parser.add_argument('--assessment_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--files_to_remove', nargs='*', help='Are there files not to consider?') #give as string '' * means zero or more
    parser.add_argument('--baseline_file', type=str, help='the file.xlsm, sotred in assessment_path, describing the baseline')
    parser.add_argument('--plot_path', type=str, help='where the sorted code list is stored ')
    parser.add_argument('--save_path', type=str, help='where to store resulting video')

    args = parser.parse_args()
    main(args)