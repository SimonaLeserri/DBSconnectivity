import argparse
import pandas as pd
import os
import numpy as np

def main(args):

    patients_dir = sorted([el for el in os.listdir(args.project_path) if el.startswith('Patient')])
    till_csv = 'VTA_tracts/plot/outcomes/Depression_scales_evolution.csv'

    table_dict = {}
    baseline_dict = {}   

    for pat in patients_dir:

        this_pat = {}    
        complete_path = os.path.join(args.project_path,pat,till_csv)
        df = pd.read_csv(complete_path) #already sorted in time and with values in percentage

        baseline_df = df[df.date == min(df.date)][['measure','value']]
        baseline_dict[pat] = dict(zip(baseline_df.measure,baseline_df.value ))
        this_pat['n_sessions'] = df.date.nunique()-1 #remove preoperative baseline date
        
        
        df['date'] = pd.to_datetime(df.date,format = '%Y-%m-%d')    
        unique_dates_no_bl = np.array(df['date'].unique()[1:])    
        time_between_assessments = np.diff(df['date'].unique()[1:]) / np.timedelta64(1,'D')
        
        # in days
        this_pat['min'] = np.min(time_between_assessments)
        this_pat['max'] = np.max(time_between_assessments)
        this_pat['std'] = np.round(np.std(time_between_assessments),2)
        this_pat['median'] = np.round(np.median(time_between_assessments),2)
        
        # in months - distance between first and last assessment
        this_pat['total_coverage(m)'] = np.ceil((unique_dates_no_bl[-1] - unique_dates_no_bl[0])/ np.timedelta64(1,'D')/30)

        table_dict[pat] = this_pat  
        sessions_df = pd.DataFrame.from_dict(table_dict).T
        baseline_values = pd.DataFrame.from_dict(baseline_dict)[::-1]

        os.makedirs(os.path.join(args.project_path, 'Tables'), exist_ok=True)
        sessions_df.to_csv(os.path.join(args.project_path, 'Tables', 'sessions_patients.csv'))
        baseline_values.to_csv(os.path.join(args.project_path, 'Tables', 'baseline_values.csv'))

    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Create table comparing sessions and baseline between patients')
    parser.add_argument('--project_path',type=str,help='Complete path to the common project folder where the patients subfolders are')
    args = parser.parse_args()
    main(args)