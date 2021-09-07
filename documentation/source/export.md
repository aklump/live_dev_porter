When exporting you have two options to decrease the file export size:

## Ignore tables altogether

1. List the tablenames, one per line in _tables.ignore.txt_
4. You may use SQL wildcards such as `foo_%` in your list.
2. Neither the structure, nor the data will appear in the export file.

## Ignore data only

3. List the tablenames, one per line in _data.ignore.txt_
4. You may use SQL wildcards such as `cache_%` in your list.
5. The export file will contain structure only. 
