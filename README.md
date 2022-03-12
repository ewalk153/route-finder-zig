# Route Finder in Zig

An offshoot of [One day in Paris](https://github.com/ewalk153/onedayinparis), this explores the code constructs of Zig by reimplementing Dijkstra's algorithm (well a variant of it) to learn about the following tasks:

 - Read and parse a structured text file (a tsv here)
 - String manipulation
 - Object initialization, and basic of memory management
 - Using advanced data structures like priority queue, and ArrayLists

Progress:
 - [x] parse text structure from a file and read into data structures
 - [x] implement basic Dijkstra route finding
 - [x] split project into multiple files
 - [x] add backtracking
 - [x] given the problem domain is train routes, lay on train line switching costs
 - [x] implement single source to all-destination Dijkstra
 - [x] write results out as a csv file (could be a file or stdout)
 - [ ] demonstrate importing code from another repository (perhaps)
 - [ ] convert Dijkstra routines to process generic types

`build_nodes.zig` holds the main code for this project.