

from sys import argv
import re

script, filename = argv
    

file = open("out.txt", "w")

def textformatter(inputtextfile):
    input = open(inputtextfile, "r")
    inputlist = []
    for line in input:
        inputlist.append(line)
    iterlist = {}
    itercount = 0
    for item in inputlist:
        item = item.rstrip("\n")
        iterlist[itercount]= item
        itercount = itercount +1
    return iterlist

surglist=textformatter(argv[1])
dicofcriteria ={}
dicofdysplasia = {}
dicofmrn = {}
empty = []
carcinoma = False
dysplasia = False


for k,v in surglist.items():
    mrn = re.findall('([0-9][0-9][0-9][0-9][0-9][0-9][0-9])',v)
    carcinoma = re.findall('(carcinoma)', v)
    dysplasia = re.findall('(dysplasia)', v)
    if len(mrn)==1 :
        dicofmrn.update({k+2:mrn[0]})
    if len(carcinoma)==1:
        dicofcriteria.update({k:carcinoma[0]})
    if len(dysplasia) == 1:
        dicofdysplasia.update({k:dysplasia[0]})

if dicofcriteria !=False:
    for k, v in dicofcriteria.items():
        for a, b in dicofmrn.items():
            if k == a:
                carcinoma = True
                stringtowrite = b + ': ' + v
                print>>file.write(stringtowrite)
            else:
                pass
else:
    carcinoma = False
if dicofdysplasia != False:
    for k, v in dicofdysplasia.items():
        for a, b in dicofmrn.items():
            if k == a:
                dysplasia = True
                dstringtowrite = b + ': ' + v
                print>>file.write(dstringtowrite)
            else:
                pass
else:
    carcinoma = False

file.close()

