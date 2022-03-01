from my_tools import *
import matplotlib.pyplot as plt
import numpy as np
import argparse
import matplotlib.lines as mlines
import pandas as pd


def bimodal_connectivity(bimodal, VTA_name, destination_folder=False, sorting=False, scaling=False):
    # define 4 color-blind friendly colors from https://gist.github.com/thriveth/8560036
    col1 = '#377eb8'
    col2 = '#ff7f00'
    col3 = '#4daf4a'
    col4 = '#a65628'

    if sorting:
        bimodal = bimodal.sort_values(by='sum_of_weight')

    fig, ax = plt.subplots(figsize=(18, 5))
    plt.title('Structural and functional connectivity for {}'.format(VTA_name), fontsize=18)

    # using the twinx() for creating another
    # axes object for secondary y-Axis
    ax2 = ax.twinx()

    # Functional
    col = np.where(bimodal.average_value < 0, col1, col2)
    ax.scatter(bimodal.label, abs(bimodal.average_value), c=col)
    if scaling:
        max_functional = max(abs(bimodal.average_value)) + max(abs(bimodal.average_value)) * 0.1
        ax.set_ylim([0, max_functional])
    else:
        ax.set_ylim([0, 0.5])

    # giving labels to the axes
    ax.set_xlabel('Brodmann Area')
    ax.set_ylabel('Mean functional connection of BA to VTA', color=col3, weight='bold')
    ax.set_xticklabels(bimodal.label, rotation=70)
    ax.tick_params(axis='y', colors=col3)
    # Structural
    if scaling:
        max_structural = max(bimodal.perc) + max(bimodal.perc) * 0.1
        ax2.set_ylim([0, max_structural])
    else:
        ax2.set_ylim([0, 100])

    ax2.bar(bimodal.label, bimodal.perc, label='Structural connectivity', color='b', alpha=0.2)
    positive = mlines.Line2D([], [], color=col1, marker='.',
                             markersize=15, label='Negative functional connectivity')
    negative = mlines.Line2D([], [], color=col2, marker='.',
                             markersize=15, label='Positive functional connectivity')

    ax2.set_ylabel('% weights VTA to BA', color=col4, weight='bold')
    ax2.tick_params(axis='y', colors=col4)

    # where some data has already been plotted to ax
    handles, labels = ax2.get_legend_handles_labels()

    # handles is a list, so append manual patch
    handles.append(positive)
    handles.append(negative)

    plt.legend(handles=handles, bbox_to_anchor=(1.25, 0.95), fancybox=True,
               shadow=True)
    # defining display layout

    if destination_folder:
        plt.savefig(os.path.join(destination_folder, 'Bimodal_connectivity_{}'.format(VTA_name)), bbox_inches='tight')
    else:
        plt.show()
    return

def main(args):
    VTA_tracts_path = os.path.join(args.patient_path, 'VTA_tracts')
    VTA_tracts = sorted([el for el in os.listdir(VTA_tracts_path) if el.startswith('VTA')])
    # loaded_stimulation_dicts = np.load(assessment_path + '/corrected_stimulations.npy', allow_pickle='TRUE')
    # get sequence of unique VTA codes in time
    sorted_code_list = np.load(args.plot_path + '/sorted_code_list.npy')
    sorted_code_list = ['VTA_' + "{0:0=2d}".format(i) for i in sorted_code_list]
    # get sequence of dates
    dates = np.load(args.plot_path + '/sorted_dates.npy')  # string with dd.mm.yyyy format
    labels = get_labels(args.parcellation_path_Brodmann, 'Brodmann')

    together = bilateral_video(labels, VTA_tracts_path, dates, sorted_code_list)

    date_to_code = dict(zip(dates, sorted_code_list))
    together['unique_VTA_code'] = together.apply(lambda x: date_to_code[x.date], axis=1)
    together.drop_duplicates(subset=['area', 'sum_of_weight', 'unique_VTA_code'], inplace=True)

    structural = together[together.unique_VTA_code == args.VTA_code.split('/')[-1]]

    functional = pd.read_csv(os.path.join(args.save_path, 'averaged_z_fingerprint.txt'), sep=' ')

    bimodal = functional.merge(structural, left_on='label', right_on='area')

    total_weight_day = bimodal.groupby(['date']).sum().to_dict()['sum_of_weight']
    bimodal['perc'] = bimodal.apply(lambda x: (x.sum_of_weight / total_weight_day[x.date]) * 100, axis=1)
    bimodal_connectivity(bimodal, args.VTA_code.split('/')[-1], args.save_path, sorting=True, scaling=False)
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='For each VTA, put together functional and structural connectivity')
    parser.add_argument('--patient_path',type=str,help='Complete path to patient VTA')
    parser.add_argument('--plot_path', type=str, help='where the sorted code list is stored')
    parser.add_argument('--save_path', type=str, help='where to store resulting video')
    parser.add_argument('--parcellation_path_Brodmann', type=str, help='Complete path till LUT of parcellation Brodmann', default='/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default.txt')
    parser.add_argument('--VTA_code',type=str, help='the complete path to the unique_VTA_code folder ')
    args = parser.parse_args()
    main(args)