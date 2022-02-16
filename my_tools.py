import pandas as pd
import os
import numpy as np
from datetime import datetime
import scipy.io as spio

def get_max(weird_string):
    #if a measure is described in a string as a 5 range A% - B%, get maximum
    new_vals = [int(''.join([x for x in el if x not in [' ','%']])) for el in weird_string.split('-')]
    return max(new_vals)

def parse_excel_outcome(filepath,max_val_assessment):
    df = pd.read_excel(filepath)

    visit_dict = {}
    visit_dict['date'] = df.iloc[3, 4]
    if visit_dict['date'] != visit_dict['date']: #if it is nan
        date_in_title = filepath.split('_')[-1].split('.xlsm')[0]
        visit_dict['date'] = date_in_title.replace('-','.')
    visit_dict['misterious_date'] = df.iloc[5, 6]
    scores_df = df.iloc[9:, 3:5]

    scores_df.columns = ['assessment_var', 'assessment_value']
    not_numeric = scores_df[scores_df.assessment_value.apply(lambda x: isinstance(x, str))]
    if len(not_numeric) > 0:
        x = get_max(scores_df.loc[not_numeric.index].assessment_value.item())
        scores_df.at[list(not_numeric.index)[0], 'assessment_value'] = x

    for scr in range(len(scores_df.index)):
        # save in percentages
        if scores_df.iloc[scr, 1] == scores_df.iloc[scr, 1]:# is measure is not none
            visit_dict[scores_df.iloc[scr, 0]] = round(
                (scores_df.iloc[scr, 1] / max_val_assessment[scores_df.iloc[scr, 0]]) * 100, 2)
        else:
            visit_dict[scores_df.iloc[scr, 0]] = np.nan

    if int(visit_dict['SOFAS'] < 1):  # sometimes this measure is defined in 0 to 1 range grr
        visit_dict['SOFAS'] = visit_dict['SOFAS'] * 100

    left = {}
    left['duration'] = df.iloc[6, 5]
    left['frequency'] = df.iloc[6, 6]
    left['stimulation'] = df.iloc[6, 4]
    if left['stimulation'] != left['stimulation']:
        print(visit_dict['date'], 'has nan LEFT stimulation')

    right = {}
    right['duration'] = df.iloc[7, 5]
    right['frequency'] = df.iloc[7, 6]
    right['stimulation'] = df.iloc[7, 4]

    if right['stimulation'] != right['stimulation']:
        print(visit_dict['date'], 'has nan ROIGHT stimulation')

    visit_dict['left'] = left
    visit_dict['right'] = right

    return visit_dict


def hemivideo(long_side, labels, vta_path, dates, sorted_code_list, mode):
    if long_side == 'left':
        short_side = 'L'
    else:
        short_side = 'R'

    ordered_list_VTA = [create_df(VTA_code, labels, vta_path, short_side, dates[i], mode) for i, VTA_code in
                        enumerate(sorted_code_list)]

    together = pd.DataFrame()
    for df in ordered_list_VTA:
        together = together.append(df, ignore_index=True)

    return together

def bilateral_video(labels, vta_path, dates, sorted_code_list):

    ordered_list_VTA = [create_bilateral_df(VTA_code, labels, vta_path, dates[i]) for i, VTA_code in
                        enumerate(sorted_code_list)]

    together = pd.DataFrame()
    for df in ordered_list_VTA:
        together = together.append(df, ignore_index=True)

    return together

def create_bilateral_df (VTA_id, labels, parent_path,date):
    base = 'Brod_vec_weight'
    full_path = os.path.join(parent_path, VTA_id, '{idx}_{bs}.csv'.format(idx=VTA_id,bs = base))

    df = pd.read_csv(full_path, comment='#', header=None)
    df.columns = labels
    df = df.T.reset_index()
    df.rename(columns={'index': 'label', 0: 'sum_of_weight'}, inplace=True)
    df[['hemi', 'area']] = df['label'].str.split('-', expand=True)
    bilateral_df = df.groupby('area').sum()['sum_of_weight'].to_frame().reset_index()

    bilateral_df.index += 1
    bilateral_df['date'] = date #string with dd.mm.yyyy format
    return bilateral_df


def create_df(VTA_id, labels, parent_path, side, date,mode):
    base = 'weighted_fingerprint' if mode == 'DKT' else 'Brod_vec_weight'
    full_path = os.path.join(parent_path, VTA_id, '{hemi}_{idx}_{bs}.csv'.format(hemi=side, idx=VTA_id,bs = base))

    df = pd.read_csv(full_path, comment='#', header=None)
    df.columns = labels
    df = df.T.reset_index()
    df.rename(columns={'index': 'label', 0: 'sum_of_weight'}, inplace=True)

    if mode == 'DKT':
        df[['segm', 'parc', 'name']] = df.label.str.split('-', expand=True)
        if side == 'L':
            df = df[(df.parc != 'rh') & (df.segm != 'Right')]
        else:
            df = df[(df.parc != 'lh') & (df.segm != 'Left')]
        df.drop(['segm', 'parc', 'name'], axis=1, inplace=True)

    elif mode == 'Brodmann':
        df['side'] = df.label.str.split('-').str[0]
        if side == 'L':
            df = df[df['side'] == 'lh']
        else:
            df = df[df['side'] == 'rh']
        df.drop('side', axis=1, inplace=True)
    else:
        raise Exception(
            'I do not known this parcellation, please choose between DKT and Brodmann')

    df.index += 1
    df['date'] = date #string with dd.mm.yyyy format
    return df

def create_assessment_df(parsed_dict,baseline_dict, baseline_assessments):
    parsed_dict[baseline_dict['date']] = baseline_assessments
    #dropna for nan assessments
    df = pd.DataFrame.from_dict(parsed_dict, orient="index").stack(dropna=False).to_frame()
    # to break out the lists into columns
    df = pd.DataFrame(df[0].values.tolist(), index=df.index)
    df = df.reset_index()
    df.columns = ['date', 'measure', 'value']
    df['date'] = pd.to_datetime(df['date'], format='%d.%m.%Y')
    df = df.sort_values(by='date')
      # length = n_assessment variables * dates assessed
    return df

def get_labels(lut_path,mode):
    lut_index = 2 if mode == 'DKT' else 1
    labels = []
    with open(lut_path) as f:
        for line in f.readlines():
            if (not line.startswith(('#', '\n', '0'))):
                labels.append([x for x in line.split(" ") if x][lut_index])
    if mode == 'DKT':
        labels = [x for x in labels if not x.endswith('Proper')]
    else:
        labels = [x[4:] for x in labels]

    return labels

def read_assessments(dates, assessment_path,baseline_file, files_to_remove ):
    #dates = [datetime.strptime(day, "%d/%m/%Y").strftime("%d.%m.%Y") for day in dates]

    list_of_assessments = ['BDI', 'HAMD', 'MADRS', 'SHAPS', 'Sheehan', 'SOFAS', 'BARS']
    max_val_assessment = dict(zip(list_of_assessments, [63, 65, 60, 14, 30, 100, 14]))  # from the summary file

    baseline_dict = parse_excel_outcome(assessment_path + '/' + baseline_file, max_val_assessment)

    baseline_assessments = {k: baseline_dict[k] for k in list_of_assessments}
    files_to_read = [file for file in os.listdir(assessment_path) if
                     not file.startswith('~') and not file.startswith('Übersicht') and file.endswith('.xlsm')]

    files_to_read = [el for el in files_to_read if el not in files_to_remove]

    # #hochfrequente Assessments_2018-10-1.xlsm')
    parsed_files = [parse_excel_outcome(assessment_path + '/' + file, max_val_assessment) for file in files_to_read]

    parsed_dict = {item['date']: item for item in parsed_files if item['date'] in dates}
    percentages_impro = parsed_dict.copy()
    for date, inner_dict in parsed_dict.items():
        parsed_dict[date] = {k: inner_dict[k] for k in list_of_assessments}
        percentages_impro[date] = {k: round(baseline_assessments[k] - inner_dict[k], 2) if k != 'SOFAS' else round(
            inner_dict[k] - baseline_assessments[k], 2) for k in list_of_assessments}

    percentages_impro = {'session_' + datetime.strptime(date, "%d.%m.%Y").strftime("%d_%m_%Y"): percentages_impro[date]
                         for ind, date in enumerate(dates)}
    spio.savemat(assessment_path + '/' + 'perc_impro.mat', percentages_impro)
    #
    df = create_assessment_df(parsed_dict, baseline_dict, baseline_assessments)
    #df has n_assessment*n-sessions rows with columns measure,date and values(already in %)
    return df
