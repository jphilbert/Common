import argparse
import xlrd
import csv
import os
import datetime


def XLStoCSVAllSheets(f, raw = False):
    wb = xlrd.open_workbook(f)
    filename = os.path.split(f)[1]
    filename = os.path.splitext(filename)[0]

    def formatXLS(x,y):
        if y == 1:
            return(x.strip())
        elif y == 2:
            return('%g' % x)
        elif y == 3:
            x = xlrd.xldate_as_tuple(x, 0)
            return(datetime.datetime(*x).strftime('%Y%m%d'))
        else:
            return(x)
    
    for s in wb.sheets():
        print("Processing Sheet: " + s.name)
        fileOut = open(filename + ' - ' + s.name + '.csv', 'wt')
        csvOut = csv.writer(fileOut)
        for rownum in xrange(s.nrows):
            if raw:
                thisRow = s.row_values(rownum)
            else:
                thisRow = [formatXLS(x, y)
                           for x,y in zip(s.row_values(rownum),
                                          s.row_types(rownum))]
            csvOut.writerow(thisRow)
        fileOut.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description = "Convert all XLS sheets to CSV Files")
    parser.add_argument('file', help = 'XLS File')
    parser.add_argument('-raw', help = 'Do not clean up cells',
                        action = 'store_true')
    
    args = parser.parse_args()

    args.file = os.path.expanduser(args.file)
    XLStoCSVAllSheets(args.file, args.raw)
