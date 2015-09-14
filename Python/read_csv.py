import ConfigParser
import os
import csv
from datetime import datetime
import logging
import re

config = ConfigParser.ConfigParser()
config

config.read(os.path.expanduser('~/Common/python/config.ini'))

config.sections()

print(config.getboolean('SectionOne', 'Value'))


path_items = config.items('Fields')

def parseFields(fields):
    def cleanField(f):
        f = f[1].split(',')
        f = map(lambda(x): x.split(), f)
        return(f)

    fields = filter(lambda(x): 'field' in x[0], path_items)
    fields = map(cleanField, fields)

    return(fields)





temp = AnalyzeFile(config)

for i in temp['fields']:
    print i
    print'\n'




print(not re.match(r'^[a-zA-Z0-9 ]*$', '\x1a'))


filter(lambda(x): re.match(r'^[a-zA-Z0-9 ]+$', x.strip()), ['', ''])
