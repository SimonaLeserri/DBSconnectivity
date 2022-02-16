import argparse
from my_tools import *

import matplotlib.animation as animation
import matplotlib.pyplot as plt

#also saves the percentage improvements needed for RMaps computations


def plot_assessment(day_assessment,df,ax,side,loaded_stimulation_dicts,destination_figure):
    data = df[df['date'] <= day_assessment]
    # we want to plot the evolution of these metrics in time
    # for dates still to follow, we want to leave an empty space
    # we therefore build an empty fake df for the future dates
    rest = pd.unique(df[df['date'] > day_assessment]['date'])
    missing_df = pd.DataFrame([[missing_date, np.nan, np.nan] for missing_date in rest], columns=df.columns)
    data = data.append(missing_df)

    ax.clear()
    # fig, ax = plt.subplots(figsize=(12,8))
    for m in pd.unique(data['measure']):
        if m == m:  # means the measure is not null

            portion_measure = data[(data['measure'] == m) | (data['measure'] != data['measure'])].sort_values(
                by=['date'])

            index = [pd.to_datetime(str(day)).strftime("%d.%m.%y") for day in portion_measure.date.values]
            index[0] = 'Baseline'
            if m == 'SOFAS':
                portion_measure.value = 100 - portion_measure.value

            if pd.to_datetime(day_assessment).strftime("%d.%m.%Y") not in [el['date'] for el in loaded_stimulation_dicts]:
                intensity = 'Baseline'
            else:
                intensity = [el['stimulation'][side]['amplitude'] for el in loaded_stimulation_dicts if
                             el['date'] == pd.to_datetime(day_assessment).strftime("%d.%m.%Y")][0]
            x = np.arange(len(index))
            ax.set_xlim(right = len(index))
            ax.set_ylim([0, 100])

            # create axes with dates along the x axis
            ax.set(xticks=x, xticklabels=index, yticks = [0,20,40,60,80,100],yticklabels=['0 \n optimal \n response', 20, 40, 60, 80, '100 \n severe \n depression'])
            ax.tick_params(axis='x', labelrotation=90)
            ax.set_xlabel('Session date')
            ax.set_ylabel('% depression scales')
            ax.set_title('Depression assessment evolution', fontsize=18, fontweight="bold")
            #
            ax.plot(x, portion_measure['value'], label=m)
            ax.legend(title='Depression scales', loc='center right', bbox_to_anchor=(1.20, 0.5), fancybox=True,
                      shadow=True)
            ax.xaxis.grid(True, color='gray', linestyle='--')

            ax.text(1.22, 0.9, pd.to_datetime(day_assessment).strftime("%d.%m.%y"), transform=ax.transAxes, size=30,
                    ha='right')
            ax.text(1.15, 0.7, intensity, transform=ax.transAxes, size=24, ha='right')

            plt.tight_layout()


    return

def main(args):

    loaded_stimulation_dicts = np.load(args.assessment_path + '/corrected_stimulations.npy', allow_pickle='TRUE')

    dates = np.load(args.plot_path + '/sorted_dates.npy')

    # the .npy files has the dates in the format "%d/%m/%Y"
    # while the original excel assessment files follow "%d.%m.%Y"


    list_of_assessments = ['BDI', 'HAMD', 'MADRS', 'SHAPS', 'Sheehan', 'SOFAS', 'BARS']
    max_val_assessment = dict(zip(list_of_assessments, [63, 65, 60, 14, 30, 100, 14]))  # from the summary file

    df = read_assessments(dates, args.assessment_path, args.baseline_file, args.files_to_remove)
    df.to_csv(os.path.join(args.save_path, 'Depression_scales_evolution.csv'))
    fig, ax = plt.subplots(figsize=(12, 8))
    side = 'left' # normally left and right stimulation are identical, but one never knows
    animator = animation.FuncAnimation(fig, plot_assessment, frames=pd.unique(sorted(df.date)), fargs = (df,ax,side,loaded_stimulation_dicts,args.save_path, ))

    writervideo = animation.FFMpegWriter(fps=2)
    os.makedirs(args.save_path, exist_ok=True)
    animator.save(os.path.join(args.save_path, 'Depression_scales_evolution.mp4'), writer=writervideo)

    # save static figure without amplitudes
    for txt in ax.texts:
        txt.set_visible(False)
    plt.savefig(os.path.join(args.save_path, 'Depression_scales_evolution'), bbox_inches='tight',dpi=600)
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Plotting the MDD measurments evolution')
    parser.add_argument('--stimulation_path',type=str,help='Complete path to patient VTA')
    parser.add_argument('--assessment_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--files_to_remove', nargs='*', help='Are there files not to consider?') #give as string '' * means zero or more
    parser.add_argument('--baseline_file', type=str, help='the file.xlsm, sotred in assessment_path, describing the baseline')
    parser.add_argument('--plot_path', type=str, help='where the sorted code list is stored ')
    parser.add_argument('--save_path', type=str, help='where to store resulting video')

    args = parser.parse_args()
    main(args)