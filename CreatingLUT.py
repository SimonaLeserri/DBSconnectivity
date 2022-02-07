import argparse


def write_increasingLUT(full_path_original):
    originalLUT = full_path_original.split('/')[-1]
    path = full_path_original.strip(originalLUT)

    new_doc = []
    counter = 1
    with open(full_path_original) as fr:
        for line in fr.readlines():
            if (not line.startswith(('#', '\n', '0','1000','2000'))): # remove the cortical unknown areas

                replacing_line = str(counter) + line[4:]  # we just replace the non continuous index that has 3 digit
                new_doc.append(replacing_line)
                counter += 1
            else:
                if not line.startswith(('1000', '2000')):
                    new_doc.append(line)

    with open(path + 'Brodmann_known_default.txt', 'w') as fw:
        for item in new_doc:
            fw.write("%s" % item)
    print('Now you have an icreasingly ordered LUT, ready to be used in MRtrix!')
    return

def main(args):
    write_increasingLUT(args.full_path)
    return

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Reading the assessment files of Patient 1')
    parser.add_argument('--full_path',type=str,help='Complete path to the Atlas Look Up Table')
    args = parser.parse_args()
    main(args)