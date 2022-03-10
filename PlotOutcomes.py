import argparse
from my_tools import *
from create_patient_instance import *

import matplotlib.animation as animation
import matplotlib.pyplot as plt
from matplotlib import rcParams, cycler

rcParams.update({'font.size': 17})


#also saves the percentage improvements needed for RMaps computations


def plot_assessment(day_assessment,df,ax,side,loaded_stimulation_dicts,destination_figure,colors):
    data = df[df['date'] <= day_assessment]
    # we want to plot the evolution of these metrics in time
    # for dates still to follow, we want to leave an empty space
    # we therefore build an empty fake df for the future dates
    rest = pd.unique(df[df['date'] > day_assessment]['date'])
    missing_df = pd.DataFrame([[missing_date, np.nan, np.nan] for missing_date in rest], columns=df.columns)
    data = data.append(missing_df)
    right_label_order = sorted([el for el in list(pd.unique(data['measure'])) if el == el])
    data = data.sort_values(by=['date','measure'])
    ax.clear()

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
            ax.set(xticks=x, xticklabels=index, yticks = [0,20,40,60,80,100],yticklabels=['0 \n No depression', 20, 40, 60, 80, '100 \n Severe \n depression'])
            ax.tick_params(axis='x', labelrotation=90)
            ax.set_xlabel('Session date')
            ax.set_ylabel('% depression scales')
            ax.set_title('Depression assessment evolution', fontsize=22, fontweight="bold")
            #
            ax.plot(x, portion_measure['value'],color = colors[m], label=m)
            ax.legend(title='Depression scales', loc='center right', bbox_to_anchor=(1.30, 0.5), fancybox=True,
                      shadow=True)
            ax.xaxis.grid(True, color='gray', linestyle='--')

            ax.text(1.22, 0.9, pd.to_datetime(day_assessment).strftime("%d.%m.%y"), transform=ax.transAxes, size=30,
                    ha='right')
            ax.text(1.15, 0.7, intensity, transform=ax.transAxes, size=24, ha='right')
            ax.xaxis.labelpad = 20

            plt.tight_layout()


    return

def main(args):

    Pat = unpickle(args.pickle_path)
    loaded_stimulation_dicts = np.load(Pat.assessment_path + '/corrected_stimulations.npy', allow_pickle='TRUE')

    dates = np.load(Pat.plot_path + '/sorted_dates.npy')

    # the .npy files has the dates in the format "%d/%m/%Y"
    # while the original excel assessment files follow "%d.%m.%Y"


    list_of_assessments = ['BDI', 'HAMD', 'MADRS', 'SHAPS', 'Sheehan', 'SOFAS', 'BARS']
    cmap = plt.cm.Dark2_r
    rcParams['axes.prop_cycle'] = cycler(color=cmap(np.linspace(0, 1, len(list_of_assessments))))
    mpp_colors = dict(zip(list_of_assessments, rcParams['axes.prop_cycle'].by_key()['color']))
    
    max_val_assessment = dict(zip(list_of_assessments, [63, 65, 60, 14, 30, 100, 14]))  # from the summary file

    df = read_assessments(dates, Pat.assessment_path, Pat.baseline_file, Pat.files_to_remove)
    df.to_csv(os.path.join(Pat.plot_path,'outcomes', 'Depression_scales_evolution.csv')) # used in create_tables
    
    os.makedirs(os.path.join(Pat.plot_path, 'outcomes'), exist_ok=True)
    fig, ax = plt.subplots(figsize=(15, 8))
    side = 'left' # normally left and right stimulation are identical, but one never knows
    animator = animation.FuncAnimation(fig, plot_assessment, frames=pd.unique(sorted(df.date)), fargs = (df,ax,side,loaded_stimulation_dicts,os.path.join(Pat.plot_path, 'outcomes'),mpp_colors ))

    writervideo = animation.FFMpegWriter(fps=2)
    
    animator.save(os.path.join(Pat.plot_path, 'outcomes','Depression_scales_evolution.mp4'), writer=writervideo)

    # save static figure without amplitudes
    for txt in ax.texts:
        txt.set_visible(False)
    plt.savefig(os.path.join(Pat.plot_path,'outcomes', 'Depression_scales_evolution_Final'), bbox_inches='tight',dpi=600)
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Plotting the MDD measurments evolution')
    parser.add_argument('--pickle_path',type=str,help='Complete path to the pickle file where the patient instance is stored')
    args = parser.parse_args()
    main(args)