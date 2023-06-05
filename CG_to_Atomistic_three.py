#!/urs/bin/python

#importing dependenices 


with open('topol.top', 'r') as file :
  filedata = file.read()
filedata = filedata.replace('../CG2AT/FINAL/', '')
with open('topol.top', 'w') as file:
  file.write(filedata)


