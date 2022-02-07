import argparse
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from my_tools import *

def draw_connectivity(date,together, ax ,abs_max, loaded_stimulation_dicts):

    data = together[together['date'].eq(date)]
    ax.clear()
    ax.barh(data['area'],data['sum_of_weight'],color = 'green')
    ax.set_xlim(0, abs_max+abs_max/10)
    ax.text(0.9, 0.9, date, transform=ax.transAxes, size=46, ha='right')
    #always simmetric stimulation
    intensity = [el['stimulation']['left']['amplitude'] for el in loaded_stimulation_dicts if el['date'] == date][0] #.replace('.','/')
    ax.text(0.9, 0.8, intensity, transform=ax.transAxes, size=24, ha='right')
    ax.set_xlabel('Sum of weights (a.u.)')
    ax.set_ylabel('Brodmann area')
    ax.set_title('Time evolution of streamline weights ending in each Brodmann area')
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
    animator.save(os.path.join(args.save_path, 'Evolution_of_Brodmann_weights.mp4'),
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