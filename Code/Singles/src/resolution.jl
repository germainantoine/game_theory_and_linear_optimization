#======= Lancer le programme =======#
# path = "D:/M1/" A SPECIFIER
# cd( path * "Projet_RO203/Singles" )
# include("src/resolution.jl")

# This file contains methods to solve an instance (heuristically or with CPLEX)
import Pkg
Pkg.add(["JuMP", "Cbc", "Plots", "GR"])  # Installe JuMP et CBC

using JuMP
using Cbc  
using Plots

include("heuristique.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(x)
	n = size(x,1)
	isOptimal = false
	isGrapheConnexe = true
	it = 0
	maxIt = 10*n
	
	start = time()
	
	singles = Model(Cbc.Optimizer)
	
	@variable(singles,y[1:n,1:n],Bin)	# == 1 ssi (i,j) blanche
	@objective(singles,Max,y[1,1])
	
	#Chiffres différents sur une ligne, zero mis à part
	@constraint(singles, lin[k in 1:n, i in 1:n], sum(y[i,j] for j in 1:n if x[i,j] == k) <= 1 )
	#Chiffres différents sur une colonne, zero mis à part
	@constraint(singles, col[k in 1:n, j in 1:n], sum(y[i,j] for i in 1:n if x[i,j]==k) <= 1)

	#pas deux cases voisines noires
	@constraint(singles, black[i in 1:n-1, j in 1:n], y[i,j]+y[i+1,j] >= 1)
	@constraint(singles, black_[j in 1:n-1, i in 1:n], y[i,j]+y[i,j+1] >= 1)

	# Solve the model
	optimize!(singles)

	println("\nJuMP.primal_status(singles) = ", JuMP.primal_status(singles), "\n")

	
	y_m = JuMP.value.(y)
	
	while !is_graph_connexe(y_m) && it < maxIt
		
		#contraintes de connexité
		@constraint(singles, sum( y[i,j] for i in 1:n for j in 1:n if y_m[i,j] == 0 ) >= 1)
		#@constraint(singles, sum( y[i,j] for i in 1:n for j in 1:n if y_m[i,j] == 1 ) <= n*n-1)
		
		optimize!(singles)
		y_m = JuMP.value.(y)
		it += 1
		println("\n----------- itération ", it, " ----------\n")
	end

    return y, JuMP.primal_status(singles) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
end

"""
tries many times heuristicSolve1. if solved, prints the grid, else prints:not solved
"""
function heuristicSolve(grille)


	println("in function heuristicSolve")
	b = 0
	n = size(grille,1)
	y = ones(Int,n,n)
	k = 0
	while b == 0 && k <= 1000*n*n
		k = k+1
		b, y = heuristicSolve1(grille)
	end
	if b == 0
		y = zeros(Int,n,n)
	end
	return y, k <= 10*n

end

"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()

    dataFolder = "data/"
    resFolder = "res/"

    # Array which contains the name of the resolution methods

    #resolutionMethod = ["cplex"]

    resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))  
        
        println("-- Resolution of ", file)
        x = readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
					println("\n---------- CPLEX ----------\n")
                    
                    # Solve it and get the results
                    y, isOptimal, resolutionTime = cplexSolve(x)
                    
                    # If a solution is found, write it
                    if isOptimal
						writeSolution(fout,y)
                    end

                # If the method is one of the heuristics
                else
                    println("\n---------- heuristic ----------\n")
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100

                       
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve(x)


                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

						writeSolution(fout,x)
						println(fout)

                    end 
                end

                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end


            # Display the results obtained with the method on the current instance
            include("../"*outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end


# solveDataSet()
performanceDiagram("graph.png")
# resultsArray("../results.tex")
