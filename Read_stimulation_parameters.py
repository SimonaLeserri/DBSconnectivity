import argparse
import os
import pandas as pd

def parse_excel(filepath):
    # Given an excel file, returns the relevant assessment and stimulation information in visit_dict
    # relying on thei constant position

    df = pd.read_excel(filepath)
    visit_dict = {}
    visit_dict['date'] = df.iloc[3, 4] #string format read dd.mm.YYYY
    visit_dict['misterious_date'] = df.iloc[5, 6]
    scores_df = df.iloc[9:, 3:5]
    for scr in range(len(scores_df.index)):
        visit_dict[scores_df.iloc[scr, 0]] = scores_df.iloc[scr, 1]

    left = {}
    left['duration'] = df.iloc[6, 5]
    left['frequency'] = df.iloc[6, 6]
    # The stimulation is either a NON REGULAR string describing the stimulation or it is a nan value
    left['stimulation'] = df.iloc[6, 4]
    if left['stimulation'] != left['stimulation']:
        print(visit_dict['date'], 'has nan LEFT stimulation')

    right = {}
    right['duration'] = df.iloc[7, 5]
    right['frequency'] = df.iloc[7, 6]
    right['stimulation'] = df.iloc[7, 4]
    # The stimulation is either a NON REGULAR string describing the stimulation or it is a nan value
    if right['stimulation'] != right['stimulation']:
        print(visit_dict['date'], 'has nan RIGHT stimulation')

    visit_dict['left'] = left
    visit_dict['right'] = right

    return visit_dict

def main(args):

    file_path = args.reading_path

    # select only the assessment excels files - PATIENT DEPENDENT!
    files_to_read = [file for file in os.listdir(file_path) if
                     not file.startswith('~') and not file.startswith('Übersicht') and file.endswith('.xlsm')]

    files_to_read = [el for el in files_to_read if el not in args.files_to_remove]

    parsed_files = [parse_excel(file_path + '/' + file) for file in files_to_read]

    # Prepare an excel file to manually change later
    raw_stimulations = pd.DataFrame(columns=['date', 'left', 'right'])

    for dictionary in parsed_files:
        raw_stimulations = raw_stimulations.append(
            {'date': dictionary['date'], 'left': dictionary['left']['stimulation'],
             'right': dictionary['right']['stimulation']}, ignore_index=True)

    raw_stimulations.to_excel(file_path + '/raw_stimulation.xlsx')
    print('Go and modify the ',file_path ,'/raw_stimulation.xlsx', 'file')
    print('Follow the example here : https://docs.google.com/spreadsheets/d/1Ekbqit_WQMZOta-b5ZS6Mpn8QgOM9rhWW3HxI7GqiPU/edit#gid=0')
    print('Call the new file standardized_parameters.ods and save it in the folder ', args.reading_path)
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Reading the assessment files of Patient 1')
    parser.add_argument('--reading_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--files_to_remove', nargs='*', help='Are there files not to consider?') #give as string '' * means zero or more
    args = parser.parse_args()
    main(args)