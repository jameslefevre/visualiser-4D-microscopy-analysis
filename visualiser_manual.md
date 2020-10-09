## 4D Visualiser for microscopy analysis

This visualiser is designed for the easy comparison of a 4d image dataset with one or more multiclass segmentations of the dataset and one or more renderings of each segmentation into object and track descriptions (object positions and sizes, meshes, track identifiers etc). While designed to visualise the outputs of a specific workflow, to facilitate broader use we provide a full specification of the data expected.

### Setup and run application

Source code is provided on [github](https://github.com/jameslefevre/visualiser-4D-microscopy-analysis). The contained folder vis4D is a [Processing 3](https://processing.org/) sketch (Java version). Processing runs on Windows, Mac and Linux and is free to download from [here](https://processing.org/download/) and installed locally without admin rights. Copy the entire repository or the folder vis4D into the Processing sketchbook folder, then run Processing and load using File > Sketchbook. The sketch can then be run using the button at the top left. It may also be compiled for Windows or Linux using File > Export Application.

Before using the application, data to be visualised should be saved in an accessible location using the format and file layout described below (Data specification).

The subfolder /data/data_selections within the vis4D sketch or application folder contains JSON files specifying data selections, but the actual data to be visualised should be stored separately.

compile this doc in linux:  pandoc -o visualiser_manual.html visualiser_manual.md

### Data Specification:

#### File Layout

The overall data is expected to be "rectangular" in the following sense, but is tolerant of incomplete data: 
 - the x,y,z,t dimensions are the same across the original image and all segmentations and corresponding probability maps
 - all segmentations have the same classes
 - each segmentation has the same set of object/track description types (using the same file names) 

The required file layout is as follows:

[root]/[original image extension]/[stackName]/slice[sliceNumber].png

[root]/[segmentationName]/[segmentation extension]/[stackName]/slice[sliceNumber].png
[root]/[segmentationName]/[probability map extension]/[stackName]/slice[sliceNumber].png

[root]/[segmentationName]/[objectDescriptionName]/[stackName]/objectStats.txt
[root]/[segmentationName]/[objectDescriptionName]/[stackName]/objectMeshes.obj
[root]/[segmentationName]/[objectDescriptionName]/[stackName]/objectAdjacencyTable.txt
[root]/[segmentationName]/[objectDescriptionName]/[stackName]/objectSkeletons.csv

[root]/[segmentationName]/[objectDescriptionName]/[track name].csv


Where

- stackName ranges over the set of filenames for the 3D image stacks, each corresponding to a time step in the sequence (see "Data selection" section for stackName to time step mapping).
- sliceNumber is an integer ranging from 0 to n-1, padded with zeros on the left to length p, where n is the z dimension (slices per image stack) and the padded size p defaults to 4 but can be reset in the JSON data selection file (parameter slicePadNumber).
- segmentationName and objectDescriptionName each range over a specified set of 1 or more names
- the three special path extensions have the following defaults, but can be modifed (see Data Selection section below)
	original image extension = deconv
	segmentation extension = segmented
	probability map extension = probability_maps
- track name must be specified


#### Image Data Format

As shown above, all image data is expected as png images, each representing an x-y slice for a specified time and z value. This should be a single-channel 8-bit image for the raw data, and RGB for segmentation and probability map images (8 bits per channel). Transparency is not expected, but will be added to the background, so the background segmentation class must be represented by black (0).


#### Object Data Format

The object representation is stored in 5 types of file (objectStats.txt, objectAdjacencyTable.txt, objectMeshes.obj, objectSkeletons.csv for each time step, plus the track file which spans time steps). The objectStats file is used to link data, and is required to allow any object data to be displayed. Other files can be skipped without repercussions beyond the absence of the data they contain. All data is linked by object id, which is unique at each time step (across all classes). These objects are not quite the same as track "nodes", which are the basic element of the track data representing a structure at a given time step (each track consists of a sequence of nodes at consecutive time steps). Each node consists of one or more objects. The reason for this difference is that the tracking algorithm may recombine objects of the same class (generally touching objects, split by the watershed split algorithm) in an integrated tracking/merging process. This is to allow the sharing of information across time to influence the final delineation of structures, improving consistency and tracking of structures. Other object information is generated separately for each time, and prior to the tracking algorithm. 


**objectStats.txt**

tab separated table with the following required fields:

- class (integer)
- id (integer)
- voxels (float) - used to filter objects by size, and to determine size of sphere shown at centre of object.
- x,y,z (float) - define the object centre

id must be unique across all objects in all classes at the given time, and correspond to the id values used in the adjacency, mesh, skeleton and track data (allowing all object data to be linked).

**objectAdjacencyTable.txt**

Holds information on adjacent/touching objects, across all classes.
Each row should contain 3 integer values, separated by commas; no header row is expected or allowed.
Each row is interpreted as id1,id2,adjacency, where id1 and id2 correspond to id values in objectStats.txt, and adjacency is some quantification of the adjacency (e.g. contact area). The order of id1 and id2 does not matter, and each pair of adjacent objects should appear exactly once.


**objectMeshes.obj**

This stores a collection of object meshes in a subset of the [Wavefront obj format](https://en.wikipedia.org/wiki/Wavefront_.obj_file).
Note that these files are parsed by simple custom code, not a fully featured obj parser.

The file must consist of consecutive blocks of text, each corresponding to an object mesh.
The first line in each block must be of the form "g Object_[id]", where id is the object id (corresponding to object ids used elsewhere).
This must be followed by lines of the form "v [x] [y] [z]", each corresponding to a vertex in the mesh; x,y,z are the coordinates (decimal numbers).
The remaining lines must be of the form "f [a] [b] [c]", where a,b,c are distinct integers referring to the vertices defined above. The number of a vertex is its position in the list of vertices (starting from 1, with the numbering restarting within each block of lines / mesh). Each line defines a triangular face of the mesh. The vertices must be listed in anti-clockwise order (viewed from outside the object), implicitly defining the normal direction.


**objectSkeletons.csv**

Comma separated values format (with header row) defining a table of skeleton branches.

The required fields are 

- Skeleton ID - the id of the object to which the skeleton branch belongs
- V1 x, V1 y, V1 z - the x,y,z coordinates of the start point
- V2 x, V2 y, V2 z - the x,y,z coordinates of the end point

**[track name].csv**

Tab seperated format with header, each row represents a track node. Note that branched tracks of arbitrary complexity are supported by the visualiser and this format.

Required fields:

- id - integer id of track node
- class - integer
- timeStep - integer; this is linked to the time steps which are associated with each stack name (see "Data selection" section).
- voxels - integer
- x,y,z - floats defining node centre
- linkedPrev - list of zero or more integers separated by semicolons; represents ids of matching nodes from the same track at the previous time (2 or more represents branches joining, zero indicates the start of a track). 
- linkedNext - list of zero or more integers separated by semicolons; represents ids of matching nodes from the same track at the previous time (2 or more represents branches joining, zero indicates the start of a track).
- adjacentNodes - list of zero or more integers separated by semicolons; represents ids of touching track nodes 
- adjacentNodeContact - list of numbers separated by semicolons, matching adjacentNodes; quantifies the amount of contact with touching track nodes.
- branchOrEnd - "TRUE" or "FALSE" (used to highlight track ends and branch points)
- objectIds - list of zero or more integers separated by semicolons; represents the ids of the objects contained in the node, allowing linkage to other object information.

The node id must be unique across all classes and all time steps, and is used to associate consecutive nodes in a track, and touching nodes.


### Data selection

After launching the app, a data selection and customisation window will appear, with default values filled in. Using the controls on the top row, this complete information can be saved as a JSON file, and reloaded later; when satisfied with the selection, press the launch button at the top right (this will also save the current data specification, which by default will be reloaded at next launch). The rest of the first (top) panel contains the most important selection controls. "Dataset location" is the path to the root directory containing the data to be shown (see data specification section above), which can be set directly or by file browser (select button). Title is the name displayed in visualiser to indicate the data being shown. The three "Data types" toggles control the main categories of data to display. Image data always includes the original and segmented images (if present). When selected, additional controls appear which allow the segmentation probability map and the original image colored by the segmentation class to be shown as well. Two additional controls also appear: the control for the gamma transform allowed range, which applies to original images only, and the minimum percentage confidence shown, which applies to probability maps only and is used to suppress low-confidence voxels which might otherwise obscure the display.

The second panel controls the time steps to be loaded and how these map to stack names. The data is arranged as a set of image stacks, one for each time point. Typically the stack names are not completely standardised, and are too numerous to specify individually, so they are looked up from a specified folder. The time step associated with a stack name is either parsed from the name by looking between two defined strings, or is the alpha-numerical position of the filename in the nominated folder (starting from 0). The stack names associated with each time step are found interactively from the nominated folder, and displayed in the List/Remove dropdown list, so mistakes can be spotted before launching. Note that the time steps here must match the time field in any track data loaded, or the track display will be incorrect.

The third panel allows selection of the segmentation folders within the root folder. There can be any number selected (including 0), corresponding to alternative segmentations of the same original images. These are the segmentationName values in the data specification section above. The optional label is to help when selecting the segmentation to show while the visualiser is running.

The fourth panel allows selection of the object folders within each segmentation folder. There can be any number selected (including 0), corresponding to alternative object representations of the same segmented image. These are the objectDescriptionName values in the data specification section above. A trackfile can also be specified, which is expected to be in the corresponding object folder. To compare multiple track files derived from the same object representation, create a new entry in the list with the same object folder but different track name; as long as they are listed consecutively, the shared data will be handled efficiently. Label appropriately so that the cases can be distinguised when running the visualiser.
 
The fifth panel repeats the basic specification of paths within the root folder, which we give in detail in the data specification section above, and allows the extensions for different image types to be edited if necessary.

The final panel contains some options which are likely to be edited less frequently. The scaling factors allow positions that are recorded in different units to be converted into a common, isotropic scale. Image data is generally in voxel units, so the x/y/z values should be the size of the voxel in the units to be used for display. The spatial offset vector should be chosen to allow data from consecutive time steps to be displayed at one time, but can be adjusted in the visualiser while running. Finally, the table on the right shows which class ids are expected in the object data, and which colors should be used to represent them. Each color is defined by 4 numbers between 0 and 255, representing red, green, blue, and alpha (transparancy). The voxel threshold is used when filtering objects by size, while the "parent" class allows a class hierachy to be defined. Where possible, each track is associated with a "parent" track, the track in the parent class with the highest total adjacency. This may represent the cell body associated with a surface structure, for instance. This feature is for use in combination with the "selected track" filter in the visualiser: optionally, the parents or children of selected tracks can be displayed as well.


### User interface

After the data selection is made and the visualiser has been launched, the interface allows you to select which data elements to display (to load new data, it is necessary to restart the app). 

The top section is used to select the overall data set (image stack and the segmentation and object representation versions). There is a section at the bottom right to allow multiple stacks (time steps) to be displayed at once. The remainder of the controls are used to select the data elements to show. Image data controls are on the left, while object data controls are on the right, with a master switch at the top of each section. There is a toggle button between these master controls to allow instant switching between image and object representations. Details are given below for each of these sections.


#### Select data set

The top section specifies the data set to display. The horizontal slider at the top selects the time step (step through with keys , and .). Below the slider, the radio button on the left selects the segmentation model to show (if more than one segmentation has been loaded), while the radio button on the right selects which object and track representation of this segmentation to show (again, if more than one has been loaded). 


#### Multi-time display

In the bottom-right corner, the "Multiple Times" toggle allows equivalent data from multiple consecutive time steps to be shown at once, with a specified spatial offset between consecutive time steps. This is designed to display tracks in particular. Showing many time steps may be resource intensive as well as hard to follow, depending on what data is displayed.


#### Image data controls 

In the image controls (left panel), we start by selecting the type of image data to show. Beneath that there is an option to hide selected channels in the segmentation, then a gamma control for the original image. Since this is an 8-bit image with values between 0 and 255, we apply the transform 

adjusted intensity = round(255*pow((original intensity)/255,gamma))

A small pause will be experienced on first use; we can then instantly switch between the original and tranformed image. The gamma is selected on a log scale, so that positive values will accentuate stronger signal, while negative values will accentuate the regions of weaker signal.

Below the gamma adjustment control is the slice display and selection. The slider on the left controls the selected slice (step through with vertical arrow keys). There are options to show the selected slice, all the slices above or below, or to show all slices but indicate the selected slice by flickering it on and off. These controls are designed to easily look at the data in slice view but place it in 3D context.

The final section (Slice axis) allows for reslicing the data along different axes. The viewer works by displaying a set of 2D slices in 3D, which is useful for some purposes but gives a limited 3D representation from some angles. The original data is expected to be sliced along the z axis (so that each 2d slice corresponds to a single z value). Clicking on X,Y, or Z will regenerate the slices of the current image so that this axis changes accordingly. The "Fixed" option will propogate this choice to each new image stack shown. The "Auto" option will reslice the displayed image stack automatically based on the viewing angle. This will avoid the "looking along the slice" effect, but at the cost of intermittant pauses when rotating the image, since the reslicing operation takes a noticable time. 


#### Object data controls 

In the object data controls (right panel), the top section controls which classes and which data elements to show. For a particular data element and class (such as class 2 meshes) the data is displayed only when the the buttons for the element, class and element+class are all active. The element+class buttons can thus be used for fine-grained control, although by default they are on and control is deferred to the separate class and element controls. 

The section below allows the objects to be shown to be filtered by size (pre-defined voxel thresholds for each class), whether they are included in tracks, or whether they are included in the currently selected tracks. This track selection (by track id) can be edited by the controls directly below; the id of a chosen track can be obtained using the "Track Id" option above. The "Parent" and "Children" options allow exploration of structure hierachy: if a hierarchy of classes has been defined, each track is associated with a "parent" track which is the track in the parent class which has the most aggregate contact over time. These buttons allow the parent or child tracks of a selected track to be shown when they otherwise would not (when the "Selected" filter is on). Filters can be applied to individual classes if required.

The "Object Colouring" control defaults to colouring by class (using a pre-defined colour associated with each class). Other options color using a pseudo-random colour map based on the object, node or track id, showing the effects of the object splitting and tracking algorithms. The "Node" and "Track" options only differ when showing branched tracks.

#### Hidden Controls

A few additional features are accessible only by key control. These are mostly for special purposes and often requiring code edits to be useful.

p: take a screenshot of visualiser window

P: toggle recording (when recording, a screen shot of the visualiser window is taken every frame, suitable for producing a movie)

\: Redo the alpha mask on the current image. Alpha masks translate the black background into transparancy. Occassionally the algorithm does not work correctly, leaving artefacts. This control is used to try again until it works.

space bar: show current camera position and view point

l: reset the camera to a hard-coded position and view point (can be set using info from space bar)

X,Y,Z,R: toggle constant rotation of view around corresponding axis, or a hardcoded axis for R

T: initiate a hard-coded timed routine (rotation and recording)






