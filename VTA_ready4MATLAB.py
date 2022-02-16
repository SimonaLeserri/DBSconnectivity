import argparse
from datetime import datetime
import pandas as pd
import numpy as np
import scipy.io as spio
from pathlib import Path

###
# ASSUMPTIONS:
# predefined structure of the corrected_stimulations.npy file
# pol 0 for inactive electtrodes and 1 for active ones
# all electrodes have imp 1
# only the first source out of 4 is used and has va == 2, the others have va == 1
# the case has always {'perc': 100, 'pol': 2}
# we want to estimate the VTA in MNI space (template direct)
# there is monopolar stimulation
# we are using model SimBio/FieldTrip (see Horn 2017)

def create_electrode_dict(perc_activation):
    # given the percentage of activation, creates the electrode dict
    # returning float is ESSENTIAL for matlab
    if perc_activation == 0: # it was previously a nan, we had to convert for practical reasons, it means that the electrode is not active
        return {'perc':0.0, 'pol': 0, 'imp': 1}
    else:
        perc_activation = float(perc_activation)
        return {'perc':perc_activation, 'pol': 1, 'imp': 1}


def not_active_source(side):
    # creates an empty fake source
    if side == 'left':
        number = 8
    else:
        number = 0
    inactive = {'k' + str(i + number): create_electrode_dict(perc_activation) for i, perc_activation in
                enumerate([0] * 8)}
    inactive['amp'] = 0.0
    inactive['va'] = 1
    inactive['case'] = {'perc': 100, 'pol': 2}

    return inactive


def get_dictMATLAB(avta, side_flag):
    avta = avta.replace(np.nan, 0.0)

    # the first half of the avta series is relative to the left stimulation, the rest is about the right
    if side_flag == 'left':
        side_info = avta.iloc[:int(len(avta) / 2)]
    else:
        side_info = avta.iloc[int(len(avta) / 2):]

    # the first element of the side series is always the amplitude, a string of type ampXmA where X is a space
    side_amp = side_info[0]
    # the other values represent, alternatively,for each electrode it sign (activation) and % activation
    # replace the sign - with 1, to be in accordance with lead DBS conventions
    side_activation = side_info.iloc[1:-2:2].replace('-', 1).to_list()
    side_content = side_info.iloc[2:-2:2]


    if side_flag == 'left':
        # moving the clinical electrode convection to the lead dbs one
        Ls1 = {'k' + str(i + 8): create_electrode_dict(perc_activation) for i, perc_activation in
               enumerate(side_content)}
        # out of the 4 sources available in LEAD DBS we are always and only using the first, set the others to FLOAT zero
        amplitude = [float(side_amp[:-3]), 0.0, 0.0, 0.0]
        Ls1['amp'] = float(side_amp[:-3])
        Ls1['va'] = 2 # identifier of an active source
        Ls1['case'] = {'perc': 100, 'pol': 2}
        Ls2 = not_active_source(side_flag)
        Ls3 = not_active_source(side_flag)
        Ls4 = not_active_source(side_flag)
        final_dict = {'Ls1': Ls1, 'Ls2': Ls2, 'Ls3': Ls3, 'Ls4': Ls4}


    else:
        Rs1 = {'k' + str(i): create_electrode_dict(perc_activation) for i, perc_activation in enumerate(side_content)}
        amplitude = [float(side_amp[:-3]), 0.0, 0.0, 0.0]
        Rs1['amp'] = float(side_amp[:-3])
        Rs1['va'] = 2
        Rs1['case'] = {'perc': 100, 'pol': 2}
        Rs2 = not_active_source(side_flag)
        Rs3 = not_active_source(side_flag)
        Rs4 = not_active_source(side_flag)
        final_dict = {'Rs1': Rs1, 'Rs2': Rs2, 'Rs3': Rs3, 'Rs4': Rs4}

    return final_dict, amplitude, side_activation


def merge_sides(avta, label):
    # given a series (df row) describing the vta stimulations parameters of a session
    # and the code of the session
    # returns a nested dict mirroring the lead-DBS default stimulation struct S
    # for VTA estimation in the MNI space
    dict_left, amp_left, act_left = get_dictMATLAB(avta, 'left')
    dict_right, amp_right, act_right = get_dictMATLAB(avta, 'right')
    stimulation = dict(dict_left, **dict_right) #merges dict
    amplitude = [amp_right, amp_left]
    activecontacts = [act_right, act_left]
    stimulation['amplitude'] = amplitude
    stimulation['activecontacts'] = activecontacts
    stimulation['label'] = label
    stimulation['active'] = [1, 1]
    stimulation['model'] = 'SimBio/FieldTrip (see Horn 2017)'
    stimulation['monopolarmodel'] = 0
    stimulation['template'] = 'direct'
    stimulation['sources'] = [1, 2, 3, 4]

    return stimulation

def flatten(d):
    # flattens out a nested dictionary by merging keys
    out = {}
    for key, val in d.items():
        if isinstance(val, dict):
            val = [val]
        if isinstance(val, list):
            for subdict in val:
                deeper = flatten(subdict).items()
                out.update({key + '_' + key2: val2 for key2, val2 in deeper})
        else:
            out[key] = val
    return out

def main(args):
    all_sessions_dict_replaced = np.load(args.reading_path + '/' + 'corrected_stimulations.npy', allow_pickle='TRUE')

    # convert date to datetime to enable sorting
    for session in all_sessions_dict_replaced:
        session['date'] = pd.to_datetime(session['date'], format='%d.%m.%Y')

    # create a dict session_code : all session information
    all_sessions_dict_replaced_sorted = {time_ordered_session_code: session for time_ordered_session_code, session in
                                         enumerate(sorted(all_sessions_dict_replaced, key=lambda d: d['date']))}

    # find the session-specific stimulation parameters
    list_values = [list(flatten(session['stimulation']).values()) for session in
                   list(all_sessions_dict_replaced_sorted.values())]

    # find the names of each stimulation parameter, common to each session
    list_keys = \
    [list(flatten(session['stimulation']).keys()) for session in list(all_sessions_dict_replaced_sorted.values())][0]

    # put all in a dataframe
    all_sessions_df = pd.DataFrame(list_values)
    all_sessions_df.columns = list_keys
    # change to float all percentages so that we can spot equal content in int/string format
    all_sessions_df[[el for el in list_keys if el.endswith('perc')]] = all_sessions_df[
        [el for el in list_keys if el.endswith('perc')]].apply(pd.to_numeric)

    # get only different stimulations - index is session code of a new stimulation
    # we can't compare easily with nan values but this information may be relevant after
    # thus we store the column index of all nan columns
    # to add them in a second moment
    not_nan_cols = list(all_sessions_df.dropna(axis=1, how='all').columns)
    nan_column_indexes = [i for i, el in enumerate(list(all_sessions_df.columns)) if el not in not_nan_cols]
    all_sessions_df = all_sessions_df.dropna(axis=1, how='all')  #index is time ordered session code
    uniques_vtas_df = all_sessions_df.drop_duplicates().reset_index().drop('index',axis=1) #index is unique vta code, previos index turns into new column name index and we drop it

    if len(all_sessions_df.drop_duplicates()) != len(all_sessions_df): # if there are replicates that is to say more session sharing stimulation
        # Group together the sessions code corresponding to unique DBS parameters
        df = all_sessions_df[all_sessions_df.duplicated(keep=False)]

        # introducing a trick that works only with all non-nan values
        df_no_nan = df.fillna(999)
        repet = df_no_nan.groupby(list(df_no_nan)).apply(lambda x: tuple(x.index)).tolist()

        repet = [list(el) for el in repet]
        melted_repetitions = [item for sublist in repet for item in sublist]
        repet = repet + [[index] for index in all_sessions_df.index.to_list() if index not in melted_repetitions]
        repet.sort()  # done inplace

        # create a dict unique_vta_code : list of sessions with common stimulation parameters
        unique_code = {i: time_ordered_session_code for i, time_ordered_session_code in enumerate(repet)}

    else:
        unique_code = {i: [i] for i in all_sessions_df.index}

    # save sorted dates
    sorted_dates = [el['date'].strftime("%d.%m.%Y") for el in list(all_sessions_dict_replaced_sorted.values())]

    # create a dict session_code : unique_vta_code not sorted
    session_code_to_unique_vta_dict = {time_ordered_session_code: unique_vta_code for unique_vta_code, sublist in
                                       unique_code.items() for time_ordered_session_code in sublist}

    # save the time sorted list of unique vta codes
    sorted_code_list = [session_code_to_unique_vta_dict[k] for k in sorted(session_code_to_unique_vta_dict.keys())]

    for index in nan_column_indexes:
        uniques_vtas_df.insert(loc=index,
                               column=list_keys[index],
                               value=np.nan)

    Path(args.patient_path+"/VTA_tracts/plot").mkdir(parents=True, exist_ok=True)
    np.save(args.patient_path + '/VTA_tracts/plot/sorted_dates', sorted_dates)
    np.save(args.patient_path + '/VTA_tracts/plot/sorted_code_list', sorted_code_list)

    ## MOVE TO MATLAB THE UNIQUE VTAS
    all_vtas_dict = {'VTA_' + "{0:0=2d}".format(vta_index): merge_sides(uniques_vtas_df.loc[vta_index],
                                                                        'VTA_' + "{0:0=2d}".format(vta_index)) for
                     vta_index in uniques_vtas_df.index}

    spio.savemat(args.MAT_path+'/'+'all_VTAs.mat', {'all_VTAs': all_vtas_dict})

    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Reading the assessment files of a Patient')
    parser.add_argument('--reading_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--patient_path', type=str, help='Complete path till the patient folder')
    parser.add_argument('--MAT_path', type=str, help='Complete path where to save the MATLAB struct relative to all VTAs (lead recon)')

    args = parser.parse_args()
    main(args)