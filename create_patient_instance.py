import argparse
import pickle
import os

def unpickle(where_pkl):
    with open(where_pkl, 'rb') as f:
        return pickle.load(f)


class Patient:
    def __init__(self, plot_path, assessment_path, baseline_file, files_to_remove, vta_path):
        self.plot_path = plot_path
        self.assessment_path = assessment_path
        self.baseline_file = baseline_file
        self.files_to_remove = files_to_remove
        self.vta_path = vta_path

    def pickle(self, where_pkl):
        pickleFile = open(where_pkl, 'wb')
        pickle.dump(self, pickleFile)
        pickleFile.close()

def main(args):
    Pat = Patient(args.plot_path, args.assessment_path, args.baseline_file, args.files_to_remove, args.vta_path)
    Pat.pickle(os.path.join(args.patient_path,args.patientID+'.pkl'))

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Creating a patient instance, where all the paths are stored')
    parser.add_argument('--assessment_path',type=str,help='Complete path to patient assessment folder')
    parser.add_argument('--files_to_remove', nargs='*', help='Are there files not to consider?') #give as string '' * means zero or more
    parser.add_argument('--baseline_file', type=str, help='the file.xlsm, sotred in assessment_path, describing the baseline')
    parser.add_argument('--plot_path', type=str, help='where the sorted code list is stored ')
    parser.add_argument('--vta_path', type=str, help='where the vta of the patients are stored')
    parser.add_argument('--parcellation_path_Brodmann', type=str, help='Complete path till LUT of parcellation Brodmann', default='/media/brainstimmaps/DATA/20xx_Projects/2025_DBSinDepression/03_Data/AtlasCollection/Brodmann/Brodmann_known_default.txt')
    parser.add_argument('--patient_path', type=str, help='the path to the patient folder')
    parser.add_argument('--patientID', type=str, help='the patient ID to be used as title for the patient instance')

    args = parser.parse_args()
    main(args)