import argparse
import pandas as pd

def main(args):
    stats_df = pd.read_csv(args.text_path,sep=' ') # read the file created in averageOptimalconnectivity.sh through shell function compute_Brodmann_average_number
   
    # for each Brodmann Area, get percentage of voxels significant in that area over all significant voxels
    stats_df['percentage_on_sig_brain'] = stats_df.apply(lambda x : round((x.n_voxels)*100/stats_df.n_voxels.sum(),2),axis = 1)
    stats_df['average_value'] = round(stats_df['average_value'],3)
    #stats_df['abs_r'] = abs(stats_df['average_value'])
    df = stats_df.sort_values(by=['percentage_on_sig_brain'],ascending = False)[['label','average_value','perthousand_sig_on_area','percentage_on_sig_brain']]
    df.to_csv(args.text_path.replace('.txt','.csv'))

    # NEED to copy the content easily in latex? uncomment and copy paste the print outcome :D
    # text_to_copy = []
    # for idx, (_,row) in enumerate(df.iterrows()):
    #     color = '\\  \rowcolor[rgb]{0.914,0.914,0.914}' if idx%2==0 else '\\'
    #     text_to_copy.append('{color} {lab} & {avg} & {th} & {sig}'.format(color=color,lab=row.label,avg=row.average_value,th=row.perthousand_sig_on_area,sig=row.percentage_on_sig_brain))
        
        
    # ''.join(text_to_copy) 
    
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Create the patient- and MDD measure specific table')
    parser.add_argument('--text_path',type=str,help='Complete path to the file where the voxels computations are stored. Normally in VTA_tracts/plot/functional/significant_Voxels_for_measure_(measure_here)_avg_nozero.txt')
    args = parser.parse_args()
    main(args)
