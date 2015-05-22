import argparse
import csv
import os
import re

def main():
    parser = argparse.ArgumentParser(description = "Analyze CSV file")
    parser.add_argument('file', help = 'File to analyze')
    parser.add_argument('-noheader', help = 'No column header',
                        action = 'store_false')
    parser.add_argument('-skip', help = 'Skips rows',
                        default = 0, type = int)
    
    args = parser.parse_args()

    args.file = os.path.expanduser(args.file)
    path, filename = os.path.split(args.file)
    filename = os.path.splitext(filename)[0]
    outFileName = '%s-DESC.csv' % filename
    outFileName = os.path.join(path, outFileName)

    # Figure out if we should skip some columns
    if args.noheader and args.skip == 0:
        fileIn = open(args.file)
        csvIn = csv.reader(fileIn)
    
        firstRow = 0
        for l in csvIn:
            if len(l) == sum(map(lambda x: 1 if len(x) > 0 else 0, l)):
                break
            args.skip += 1

        fileIn.close()

    # Split the skipped / junk from the file
    if args.skip > 0:
        print('Splitting file: %s header rows found' % args.skip)

        os.system("head -n " + str(args.skip) + ' "' +
                  args.file +
                  '" > "' + os.path.join(path, '%s-HEADER.csv' % filename) +
                  '"')
        os.system("tail -n +" + str(args.skip + 1) + ' "' +
                  args.file +
                  '" > "' + os.path.join(path, '%s-tail.csv' % filename) +
                  '"')
        os.system('mv "' +
                  os.path.join(path, '%s-tail.csv' % filename) + '" "' +
                  args.file + '"')

    fileIn = open(args.file)
    csvIn = csv.reader(fileIn)

    dictionary = list()
    
    l = next(csvIn)
    dictionary = list()
    nRows = 1
    nBadRows = 0
    
    for i in range(len(l)):
        dictionary.append({'name': 'n/a',
                   'initialString': '',
                   'maxLength': 0,
                   'maxString': ''})

    if args.noheader:
        for i in range(len(l)):
            dictionary[i-1]['name'] = l[i-1]
        l = next(csvIn)

      
    for i in range(len(dictionary)):
        dictionary[i-1]['initialString'] = l[i-1]
        dictionary[i-1]['maxLength'] = len(l[i-1])
        dictionary[i-1]['maxString'] = l[i-1]

        
    for i in csvIn:
        nRows += 1
        if len(i) != len(dictionary):
            nBadRows += 1 
        for j in range(len(dictionary)):
            if dictionary[j-1]['maxLength'] < len(i[j-1]):
                dictionary[j-1]['maxLength'] = len(i[j-1])
                dictionary[j-1]['maxString'] = i[j-1]
    fileIn.close()

    print('Rows: %s' % nRows)
    print('Bad Rows: %s' % nBadRows)

    fileOut = open(outFileName, 'wt')
    csvOut = csv.writer(fileOut)

    csvOut.writerow(('Column Name',
                     'Database Name',
                     'Type',
                     'Format',
                     'Drop',
                     'Description',
                     'First Value',
                     'Max Length',
                     'Max Value'))
    for i in dictionary:
        csvOut.writerow((i['name'],
                         re.sub(' +', '_',
                                i['name'].lower().strip()),
                         'varchar(%s)' % max(1, i['maxLength']),
                         '',
                         1 - min(1, i['maxLength']),
                         '',
                         i['initialString'],
                         i['maxLength'], i['maxString']))
    fileOut.close()


if __name__ == "__main__":
    main()
