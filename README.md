# construction-schedule-optimisation
construction schedule generation and optimisation


This page gives a brief overview of the functionalities of the software tool. 

The software implementation in this study consists of the following three parts:


- An Excel add-in & To read component information from BIM (.ifc) file into Excel spreadsheet

- A MATLAB standalone execution file, to:
    
Map the components with their activity, duration, cost and resource data in the database;
Formulate, solve and display the result of the MOO problem, after taking user inputs;
Write the schedule into Excel.

- An Excel macro & To write the schedule from Excel spreadsheet into Project (.mpp) file



\section{List of customisable settings}

The software tool is designed in such a way that: (1) it is applicable to not only the case studies covered in this project, but more general cases; (2) the user is allowed to alter some problem settings according to their preferences. This implies customisable settings for:





Processing the information from input files (component spreadsheet)

    & Convert the units into the ones required in the problem, if different length-related units (i.e. mm or m) are used in different projects.
    
    & Filter the components which are to be / not to be included when scheduling, by checking if their name or class contains user-specified terms, as not all components are needed in the final schedule. \vspace{3mm}\newline  e.g. "keep/delete" components which contain the term "washer" in their "name/class". 
    
    & Modify material and class names into ones that are recognisable to the tool (so that the components can be mapped properly with the database), if different names are used in different projects. \vspace{3mm}\newline  e.g. change material name from "beton" (\textit{concrete} in Dutch language) to "concrete". 
    
    

Sequencing rules

    & Adjust the sequence of structural component (clusters) by class, by ranking the classes per desirable sequence. \vspace{3mm}\newline  e.g.  & \ref{fig: UI-seqRule/seq-withinFloorLevel} \\ \cline{2-3}
    & Tighten or loosen the criteria for special spatial relations (SSR) and component size relations (CSR). \vspace{3mm}\newline  e.g. change parameters such as $D_{wallmin}$, $D_{minX}$. & \ref{fig: UI-seqRule/seq-mepSSRCSR} \\ \cline{2-3}
    

Options for optimisation problem}

    & Choose between a priori and a posteriori. \vspace{3mm}\newline  For a priori: set weights of objectives, \vspace{3mm}\newline  For a posteriori: set the number of points to check 
    
    & Change the termination criteria. \vspace{3mm}\newline  e.g. maximum running time.




