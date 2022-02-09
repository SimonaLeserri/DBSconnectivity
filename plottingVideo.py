import argparse
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from my_tools import *

def brodmann_color_dictionaries():
    # area - function association from http://www.brainm.com/software/pubs/dg/BA_10-20_ROI_Talairach/Brodmann%20Atlas%20-%20Functions%20associated%20with%20area%20-%20CLICK%20ANY%20AREA%20to%20view%20functions.htm
    function_area_dict = {'Executive': [9, 10, 44, 45, 46, 24],
                         'Memory': [20, 21, 37, 23, 27, 28, 36, 35],
                         'Motor': [4, 6, 8, 32],
                         'Emotional': [11, 47, 38, 25, 12, 38, 13],
                         'Olfactory': [34],
                         'Somatosensory': [1, 2, 3, 5, 40, 43, 31],
                         'Not clear': [26, 29, 30,33],
                        'Insular' : [16],
                         'Attention': [7, 39],
                         'Visual': [17, 18, 19],
                         'Sound': [41, 42, 22]}
    # from https://github.com/matplotlib/matplotlib/issues/9460
    colorblind_friendly_colors = ["#3f90da", "#ffa90e", "#94a4a2", "#bd1f01",  "#832db6", "#a96b59", "#e76300",
                                      "#b9ac70", "#717581", "#92dadd","#c849a9"]
    function_color_dict = {function: colorblind_friendly_colors[i] for i, function in
                           enumerate(function_area_dict.keys())}
    area_function_dict = {area: function for function, area_list in function_area_dict.items() for area in area_list}
    area_color_dict = {area: function_color_dict[function] for area, function in area_function_dict.items()}

    return area_color_dict, function_color_dict

def draw_connectivity(date,together, ax ,abs_max, loaded_stimulation_dicts):
    # colours according to BA function areas
    # http://www.brainm.com/software/pubs/dg/BA_10-20_ROI_Talairach/Brodmann%20Atlas%20-%20Functions%20associated%20with%20area%20-%20CLICK%20ANY%20AREA%20to%20view%20functions.htm
    data = together[together['date'].eq(date)]
    data['orderedBA'] = data.apply(lambda x : int(x.area.split('_')[0][2:]),axis = 1 )
    area_color_dict, function_color_dict = brodmann_color_dictionaries()
    data['color'] = data.apply(lambda x : area_color_dict[x.orderedBA] ,axis = 1 )
    legenditems = [(plt.Rectangle((0, 0), 1, 1, color=col), function)
                   for function, col in function_color_dict.items()]
    data = data.sort_values(by='orderedBA', ascending=False)

    ax.clear()
    ax.barh(data['area'],data['sum_of_weight'], color=data['color'])
    ax.set_xlim(0, abs_max+abs_max/10)
    ax.text(0.9, 0.9, date, transform=ax.transAxes, size=46, ha='right')

    # always simmetric stimulation
    intensity = [el['stimulation']['left']['amplitude'] for el in loaded_stimulation_dicts if el['date'] == date][0] #.replace('.','/')
    ax.text(0.9, 0.8, intensity, transform=ax.transAxes, size=24, ha='right')
    ax.set_xlabel('Sum of weights (a.u.)')
    ax.set_ylabel('Brodmann area')
    ax.set_title('Time evolution of streamline weights ending in each Brodmann area')
    plt.legend(*zip(*legenditems), loc='center right',
               bbox_to_anchor=(1.20, 0.5), fancybox=True,
               shadow=True, title='Approximative function \n of Brodmann Areas')
    plt.tight_layout()

def main(args):

    ## RETRIEVE INFO
    # get vta subfolders
    # get stimulations parameters
    loaded_stimulation_dicts = np.load(args.assessment_path + '/corrected_stimulations.npy', allow_pickle='TRUE')
    # get sequence of unique VTA codes in time
    sorted_code_list = np.load(args.plot_path + '/sorted_code_list.npy')
    sorted_code_list = ['VTA_' + "{0:0=2d}".format(i) for i in sorted_code_list]
    # get sequence of dates
    dates = np.load(args.plot_path + '/sorted_dates.npy') #string with dd.mm.yyyy format
    labels = get_labels(args.parcellation_path_Brodmann, 'Brodmann')

    together = bilateral_video(labels, args.vta_path, dates, sorted_code_list)

    abs_max = max(together['sum_of_weight'])
    fig, ax = plt.subplots(figsize=(14, 12))

    animator = animation.FuncAnimation(fig, draw_connectivity, frames=dates,
                                       fargs=(together, ax, abs_max, loaded_stimulation_dicts,))
    writervideo = animation.FFMpegWriter(fps=2)
    os.makedirs(args.save_path, exist_ok=True)
    animator.save(os.path.join(args.save_path, 'Evolution_of_Brodmann_weightsNEW.mp4'),
                  writer=writervideo)

    # # had to run this sudo chmod -R 777 /media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data
    # # in order to be able to copy/write/move to anything
    return


if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Plotting the vta 2 cortex connectivity')
    parser.add_argument('--vta_path',type=str,help='Complete path to patient VTA')
    parser.add_argument('--assessment_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--plot_path', type=str, help='where the sorted code list is stored ')
    parser.add_argument('--save_path', type=str, help='where to store resulting video')
    parser.add_argument('--parcellation_path_DKT', type=str, help='Complete path till LUT of parcellation DKT',default='/usr/local/mrtrix3/share/mrtrix3/labelconvert/fs_default.txt') #e.g.
    parser.add_argument('--parcellation_path_Brodmann', type=str, help='Complete path till LUT of parcellation Brodmann', default='/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default.txt')


    args = parser.parse_args()

    main(args)