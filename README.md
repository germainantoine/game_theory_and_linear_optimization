This project consists of the comparison of MILP and heuristic solving of two games, Towers and Singles.
To see all results, please read the .pdf provided with this folder.

To run the project, follow the following instructions: (if you do not have julia or tex downloaded on your computer, see below)
 - open a cmd terminal and join the folder of your choice using the cd command
 - copy this command: 
'''
git clone https://github.com/germainantoine/game_theory_and_linear_optimization.git && cd game_theory_and_linear_optimization
'''



# Towers game

### See results

Once the git repository is set up, run this command to visualize the results:
'''
cd Code\Towers && julia src\io.jl && pdflatex array.tex && start graph.png
'''
All the solved game instances are available in the res folder.

### Run the entire code from scratch

To generate the game instances and solve them, uncomment the generateDataSet and solveDataSet functions in the resolution.jl file and run this command:
'''
julia src\resolution.jl
'''



# Singles game

### See results

Once the git repository is set up, run this command to visualize the results:
'''
cd Code\Singles && julia src\resolution.jl && start graph.png
'''
All the solved game instances are available in the res folder.

### Run the entire code from scratch

To generate the game instances and solve them, uncomment the solveDataSet functions in the resolution.jl file and run this command:
'''
julia src\resolution.jl
'''



##### Download julia

To download julia, run the following command in the cmd:
'''
winget install julia -s msstore
'''