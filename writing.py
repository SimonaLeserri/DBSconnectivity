import argparse

def main(args):
    index_file = open(args.CompletePath+"/DWI/eddy/index.txt","w+")
    index_file.writelines(' '.join(str([1 for _ in range(args.Directions)])[1:-1].split(',')))

    if args.PhaseEncodingDirection == 'j':
        string_vector = "0 1 0 "
    elif args.PhaseEncodingDirection == 'j-':
        string_vector = "0 -1 0 "
    else:
        raise Exception('Unable to interpret correctly the phase encoding of this image. Please provide manually the index.txt file and place it in Path/pat/DWI/synb0/INPUTS/acqparam.txt')
    
    acqparam_file_s = open(args.CompletePath+"/DWI/synb0/INPUTS/acqparams.txt","w+")
    acqparam_file_e = open(args.CompletePath+"/DWI/eddy/acqparams.txt","w+")

    first_line = string_vector+'{:.3f}'.format(args.TotalReadoutTime)
    splitted = first_line.split(' ')
    splitted[1] = str(int(float(splitted[1])*-1))
    second_line = ' '.join(splitted)
    for L in [first_line, string_vector+'{:.3f}'.format(0.0)]:
        acqparam_file_s.writelines('  '+L+'\n')

    for L in [first_line, second_line]:
        acqparam_file_e.writelines('  '+L+'\n')
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Writes the files required to run synb0 and eddy')
    parser.add_argument('--CompletePath',type=str,help='The path/pat directory')
    parser.add_argument('--PhaseEncodingDirection',type=str,help='The phase Encoding direction for the dwi')
    parser.add_argument('--TotalReadoutTime',type=float,help='TotalReadoutTime')
    parser.add_argument('--Directions',type=int,help='number of directions')
    
    args = parser.parse_args()
    main(args)