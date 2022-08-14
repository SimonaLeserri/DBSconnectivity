import argparse
from my_tools import *
import matplotlib.pyplot as plt
from matplotlib import rcParams, cycler

rcParams.update({'font.size': 17,'font.family':'STIXGeneral'})

def cherry_colors ():
    col = plt.get_cmap('tab20')
    col = list(col.colors)
    col[0::2]+col[1::2]
    colors = np.asarray([list(el) + [1.0] for el in col])
    shown_BAs = ['BA25','All others','BA18','BA7','BA47','BA38','BA20','BA35_36','BA16','BA11','BA19','BA17','BA27','BA26_29_30','BA23']
    colors_shown = dict(zip(shown_BAs,colors))
    colors_shown['BA35_36'] = colors[-1]
    return colors_shown


def change_alpha(four_el_array):
    four_el_array[-1] = 0.5

    return four_el_array

def every_other4(lst):
    return lst[0::4] + lst[1::4] + lst[2::4] + lst[3::4]

def change_order(lst):
    #given [11,12,13,14,15] returns [15,14,11,12,13]
    #given [11,12,13,14,15,16] returns [16,15,14,11,12,13]
    if len(lst) %2: #odd
        new_order = lst[::-1][0:len(lst)//2]+lst[0:len(lst)//2+1]
    else:
        new_order = lst[::-1][0:len(lst) // 2] + lst[0:len(lst) // 2 + 1][0:-1]

    return new_order
def minimize(portion,numb):
    portion = portion.sort_values(by='perc',ascending=False)
    reduced = portion.iloc[:numb].append(portion.iloc[numb:].sum(),ignore_index=True)
    reduced.at[numb,'area'] = 'All other'
    reduced.at[numb,'date'] = reduced.iloc[0].date
    return reduced


def all_ranks(measure_dict):
    all_ranks = {}
    for key in measure_dict.keys():
        single = measure_dict[key].copy()
        single['date'] = single.apply(lambda x: pd.to_datetime(x.date, format='%d.%m.%Y'), axis=1)
        single_no_baseline = single.sort_values(by='date').iloc[1:]
        baseline = single.sort_values(by='date').iloc[0].value
        #deal with nan
        if baseline != baseline:
            baseline = single.sort_values(by='date').iloc[1].value
        single_no_baseline['perc_impro'] = single_no_baseline.apply(
            lambda x: round(baseline - x.value, 2) if key != 'SOFAS' else round(x.value - baseline, 2), axis=1)
        single_no_baseline['rank'] = single_no_baseline.value.rank(method='dense')

        all_ranks[key] = single_no_baseline

    return all_ranks

def plot_connectivity(dataframe,save_dir,common_colors_dict):
    # dataframe has as many rows as there are sessions, the date column and one more column than numb (used in minimize )

    fig, ax = plt.subplots(figsize=(12, 8))

    dataframe['date'] = dataframe.apply(lambda x: pd.to_datetime(x.date, format='%d.%m.%Y'), axis=1)  # datetime
    dataframe = dataframe.sort_values(by='date')

    dataframe['date'] = dataframe.date.dt.strftime('%d-%m-%Y')
    x = dataframe.date
    to_use = dataframe.drop('date', axis=1).fillna(0)

    cmap = plt.cm.tab20
    rcParams['axes.prop_cycle'] = cycler(color=cmap(np.linspace(0, 1, len(to_use.columns))))
    mpp_colors = dict(zip(to_use.columns, rcParams['axes.prop_cycle'].by_key()['color']))

    indexes = np.argsort(to_use.values).T  # row by row get order, then transpose
    heights = np.sort(to_use.values).T  # sorts row by row, then transpose
    order = -1
    bottoms = heights[::order].cumsum(
        axis=0)  # reads heights from bottom row to first row, then second row is sum first + second ecc
    bottoms = np.insert(bottoms, 0, np.zeros(len(bottoms[0])), axis=0)  # adds a first row of zeros
    for btms, (idxs, vals) in enumerate(list(zip(indexes, heights))[::order]):
        mps = np.take(np.array(to_use.columns), idxs)  # get name of column at idxs
        ax.bar(x, height=vals, bottom=bottoms[btms], color=[common_colors_dict[m] for m in mps])

    ax.set_ylim(bottom=0, top=102)
    text_legend = [el.replace('BA','BA ') for el in to_use.columns]
    text_legend = [el.replace('_',' & ') for el in text_legend]

    plt.legend((np.take(np.array(text_legend), np.argsort(to_use.values)[0]))[::order], loc='center right',
               bbox_to_anchor=(1.25, 0.5), fancybox=True,
               shadow=True, title='Brodmann area')
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    plt.xticks(rotation=45)
    plt.yticks(np.arange(0, 101+1, 10))
    plt.title('VATs\' structural connectivity profiles')
    plt.xlabel('date')
    plt.ylabel('% of strength connectivity')
    #plt.show()
    plt.savefig(os.path.join(save_dir, 'Time_sorted_VTAs_colors_FINAL'), bbox_inches="tight")

    return

def visualize_connectivity(df, n_areas,save_dir, show=False,common_colors = False):
    # df comes from the '{hemi}_{idx}_Brod_vec_weight.csv' and has columns label, sum_of_weight, date
    total_weight_day = df.groupby(['date']).sum().to_dict()['sum_of_weight']
    df['perc'] = df.apply(lambda x: (x.sum_of_weight / total_weight_day[x.date]) * 100, axis=1)
    minimized = df.groupby('date', as_index=False).apply(lambda x: minimize(x, n_areas)).reset_index()
    pivoted = minimized.pivot(index='date', columns='area', values='perc').reset_index().sort_values(by='date')
    if show:
        plot_connectivity(pivoted,save_dir, common_colors)
    else:
        pivoted['date'] = pivoted.apply(lambda x : pd.to_datetime(x.date,format = '%d.%m.%Y'),axis=1) #here is the problem
    return pivoted, df

def define_pattern(i):
    pattern = None
    if i % 2 == 0:
        pattern = '///'
    return pattern
def plot_connectivity_rank(dataframe, sorting,save_dir,common_colors_dict):
    bar_width = 0.8
    # dataframe has as many rows as there are sessions,
    # the date column and one more column than numb (used in minimize ) to describe cortical areas
    # the variable column

    fig, ax = plt.subplots(figsize=(12, 8))
    dataframe = dataframe.sort_values(by=[sorting, 'date'], ascending=False).reset_index()
    last_good = len(dataframe[dataframe[sorting] >= 50])
    dictio = dataframe[sorting].to_dict()  # changed 'date to sorting'

    x = dataframe.index
    to_use = dataframe.drop(['date', sorting, 'index'], axis=1).fillna(0)

    cmap = plt.cm.tab20
    rcParams['axes.prop_cycle'] = cycler(color=cmap(np.linspace(0, 1, len(to_use.columns))))
    mpp_colors = dict(zip(to_use.columns, rcParams['axes.prop_cycle'].by_key()['color']))

    indexes = np.argsort(to_use.values).T  # row by row get order, then transpose

    heights = np.sort(to_use.values).T  # sorts row by row, then transpose
    order = -1
    bottoms = heights[::order].cumsum(
        axis=0)  # reads heights from bottom row to first row, then second row is sum first + second ecc
    bottoms = np.insert(bottoms, 0, np.zeros(len(bottoms[0])), axis=0)  # adds a first row of zeros
    # mpp_colors = dict(zip(to_use.columns, plt.rcParams['axes.prop_cycle'].by_key()['color']))

    # OPTION 1 just go with the flow - same ax size, different bar size, no space
    for btms, (idxs, vals) in enumerate(list(zip(indexes, heights))[::order]):
        mps = np.take(np.array(to_use.columns), idxs)  # get name of column at idxs
        ax.bar(x, height=vals,width=bar_width, bottom=bottoms[btms], color=[common_colors_dict[m] for m in mps]) # do we want borders around every coor? edgecolor = 'black',linewidth=1)
    # # OPTION 2 same axis size, same bar size, a lot of empty space in between
    # for btms, (idxs, vals) in enumerate(list(zip(indexes, heights))[::order]):
    #     mps = np.take(np.array(to_use.columns), idxs)  # get name of column at idxs
    #     ax.bar(x, height=vals,width=bar_width/(36/len(x)), bottom=bottoms[btms], color=[common_colors_dict[m] for m in mps]) #36 is number of columns of pat1
    # # OPTION 3 same axis size, same bar width buz a lot of empty space on the right Nicer but requires moving legend, title
    # for btms, (idxs, vals) in enumerate(list(zip(indexes, heights))[::order]):
    #     mps = np.take(np.array(to_use.columns), idxs)  # get name of column at idxs
    #     ax.bar(x, height=vals,width=bar_width, bottom=bottoms[btms], color=[common_colors_dict[m] for m in mps])
    # ax.set_xlim(-1,36) #36 is number of columns of pat1


    ax.xaxis.labelpad = 20
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_ylim(bottom=0, top=102)

    text_legend = [el.replace('BA','BA ') for el in to_use.columns]
    text_legend = [el.replace('_',' & ') for el in text_legend]
    ax.legend((np.take(np.array(text_legend), np.argsort(to_use.values)[0]))[::order], loc="right",bbox_to_anchor=(1.25, 0.5),fancybox=True,
               shadow=True, title='Brodmann area')

    ax.set_xticks(x, [dictio[el] for el in x], rotation=-45)  # removed strftime()
    ax.set_yticks(np.arange(0, 101+1, 10))
    if last_good != 0:
        ax.axvline(x=last_good - 0.5, color='k', linestyle='--')
    ax.set_title('VATs\' structural connectivity profiles, ranked by clinical measure: {m}'.format(m=sorting), y = 1.03)
    ax.set_xlabel('% improvement with respect to baseline')
    ax.set_ylabel('% of strength connectivity')
    #plt.show()
    fig.savefig(os.path.join(save_dir, '{what}_sorted_VTAs_colors_FINAL'.format(what=sorting)), bbox_inches="tight",dpi=300)

    return

def ranked_connectivity(ranks_dict, pivoted_df,save_dir, common_colors):
    for measure, measure_df in ranks_dict.items():

        dictionary = measure_df[['date', 'perc_impro']].set_index('date').to_dict()['perc_impro']
        piv_copy = pivoted_df.copy()
        piv_copy[measure] = piv_copy.apply(lambda x: dictionary[x.date], axis=1)

        plot_connectivity_rank(piv_copy, measure,save_dir,common_colors)

    return

def main(args):
    sorted_code_list = np.load(args.plot_path + '/sorted_code_list.npy')
    sorted_code_list = ['VTA_' + "{0:0=2d}".format(i) for i in sorted_code_list]
    loaded_stimulation_dicts = np.load(args.assessment_path + '/corrected_stimulations.npy', allow_pickle='TRUE')

    dates = np.load(args.plot_path + '/sorted_dates.npy')
        # thesis version with assessment files everywhere
        # df = read_assessments(dates, args.assessment_path, args.baseline_file, args.files_to_remove)
    df = read_FINAL_assessments(args.plot_path + '/sorted_dates.npy', args.assessment_path, args.baseline_file,args.FINAL)

    all_measures = {'{}'.format(scale): df[df.measure == scale] for scale in list(df.measure.unique())}
    ranks = all_ranks(all_measures)
    mode = 'Brodmann' #maybe we will like the Dkt at some point
    labels = get_labels(args.parcellation_path_Brodmann, mode)
    # for side in ['left','right']:
    bilateral_df = bilateral_video(labels, args.vta_path, dates, sorted_code_list)
    bilateral_labels = list(bilateral_df.area.unique())
    bilateral_labels.append('All other')
    bilateral_labels = every_other4(bilateral_labels)
    #bilateral_labels = change_order(bilateral_labels)
    cmap = plt.cm.tab20
    rcParams['axes.prop_cycle'] = cycler(color=cmap(np.linspace(0, 1, 40)))
    list_arrays = rcParams['axes.prop_cycle'].by_key()['color']
    list_arrays_alpha = [change_alpha(el) if i % 2 == 0 else el for i, el in enumerate(list_arrays)]
    my_colors = dict(zip(bilateral_labels, list_arrays_alpha))
    cherry = cherry_colors()
    my_cherry_colors = {k:(val if k not in cherry.keys() else cherry[k]) for k,val in my_colors.items()}
    print('cherry has this many keys ',len(cherry))
    print('Is there a change? ', my_cherry_colors.values() == my_colors.values())
    colors = dict(zip(bilateral_labels, rcParams['axes.prop_cycle'].by_key()['color']))

    piv,df4plots = visualize_connectivity(bilateral_df, args.n_areas,args.save_path, show=True, common_colors=my_cherry_colors)
    # for thesis plots
    ranked_connectivity(ranks, piv, args.save_path, my_cherry_colors)
    # for heatmap
    full_connectivity_df = get_heat_data(df4plots,ranks)
    full_connectivity_df.to_csv(os.path.join(args.save_path, 'data4heatmap.csv'),index=False)


    return
if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Plotting the vta 2 cortex connectivity')
    parser.add_argument('--n_areas',type=int, help='How many individual areas do you want to plot?')
    parser.add_argument('--vta_path',type=str,help='Complete path to patient VTA')
    parser.add_argument('--FINAL', type=str, help='where the FINAl tidy file  is stored ')
    parser.add_argument('--assessment_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--plot_path', type=str, help='where the sorted code list is stored ')
    parser.add_argument('--save_path', type=str, help='where to store resulting video')
    parser.add_argument('--files_to_remove', nargs='*',
                        help='Are there files not to consider?')  # give as string '' * means zero or more
    parser.add_argument('--baseline_file', type=str,
                        help='the file.xlsm, sotred in assessment_path, describing the baseline')
    parser.add_argument('--parcellation_path_Brodmann', type=str, help='Complete path till LUT of parcellation Brodmann',default= '/home/brainstimmap/Documents/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default.txt')
    args = parser.parse_args()
    main(args)
