class_name CsvTable
extends RefCounted
## A CSV file with a header row, read into one dictionary per row keyed by column name.

var rows: Array[Dictionary] = []
var errors: PackedStringArray = []


static func load_file(path: String) -> CsvTable:
	var table := CsvTable.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		table.errors.append("%s: cannot open (%s)" % [path, error_string(FileAccess.get_open_error())])
		return table

	var header := file.get_csv_line()
	var line_number := 1
	while not file.eof_reached():
		var cells := file.get_csv_line()
		line_number += 1
		if cells.size() == 1 and cells[0].strip_edges().is_empty():
			continue
		if cells.size() != header.size():
			table.errors.append("%s:%d: expected %d columns, got %d" % [path, line_number, header.size(), cells.size()])
			continue
		var row := {}
		for i in header.size():
			row[header[i].strip_edges()] = cells[i].strip_edges()
		table.rows.append(row)
	return table
