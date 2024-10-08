#Pour executer le code:
# cd("D:/M1/RO203/Projet_RO203/Towers") Chemin à modifier
# include("src/resolution.jl")
# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(nord,sud,ouest,est)
	n = size(nord,1)
    # Create the model
    m = Model(CPLEX.Optimizer)

	@variable(m,x[1:n,1:n,1:n],Bin) # ==1 ssi (i,j) contient k
	@variable(m,yn[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis le nord
	@variable(m,ys[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis le sud
	@variable(m,yo[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis l'ouest
	@variable(m,ye[1:n,1:n],Bin)	# ==1 ssi (i,j) visible depuis l'est
	
	
	#Une seule valeur par case
	@constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,k] for k in 1:n) == 1)
	#Chiffres différents sur une ligne
	@constraint(m, [i in 1:n, k in 1:n], sum(x[i,j,k] for j in 1:n) == 1)
	#Chiffres différents sur une colonne
	@constraint(m, [j in 1:n, k in 1:n], sum(x[i,j,k] for i in 1:n) == 1)

	#nb tours visibles respecté
	
	#Nord
	@constraint(m, [j in 1:n], sum(yn[i,j] for i in 1:n)==nord[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yn[i,j]<=1-sum(x[i_,j,k_] for i_ in 1:i-1 for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yn[i,j]>=1-sum(x[i_,j,k_] for i_ in 1:i-1 for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	#Sud
	@constraint(m, [j in 1:n], sum(ys[i,j] for i in 1:n)==sud[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], ys[i,j]<=1-sum(x[i_,j,k_] for i_ in i+1:n for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], ys[i,j]>=1-sum(x[i_,j,k_] for i_ in i+1:n for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	#Est
	@constraint(m, [i in 1:n], sum(ye[i,j] for j in 1:n)==est[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], ye[i,j]<=1-sum(x[i,j_,k_] for j_ in j+1:n for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], ye[i,j]>=1-sum(x[i,j_,k_] for j_ in j+1:n for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	
	#Ouest
	@constraint(m, [i in 1:n], sum(yo[i,j] for j in 1:n)==ouest[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yo[i,j]<=1-sum(x[i,j_,k_] for j_ in 1:j-1 for k_ in k:n)/(2*n)+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yo[i,j]>=1-sum(x[i,j_,k_] for j_ in 1:j-1 for k_ in k:n)-2*n*(1-x[i,j,k]))
	
	@objective(m,Max,x[1,1,1])
	
    # Start a chronometer
    start = time()

    # Solve the model
    optimize!(m)
	
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return x,JuMP.primal_status(m) == JuMP.MathOptInterface.FEASIBLE_POINT, time() - start
    
end


"""
Heuristically solve an instance
"""
function heuristicSolve(nord,sud,ouest,est)
	n = size(nord,1)
	t = Array{Int64,2}(zeros(n,n))
	maxit = 1e6
	
	filledCases = initialize(t,nord,sud,ouest,est)
	
	coupsJoues = []
    gridFilled = false
    gridStillFeasible = true

	# Values which can be assigned to each cell
	values = Matrix{Union{Nothing,Array{Int64}}}(nothing,n,n)
	
	l = ceil.(Int, n * rand())
	c = ceil.(Int, n * rand())
	
	## ========= On prend la première cellule nulle trouvée ========== ##
	id = 1
	while t[l,c] != 0 && id < n*n
		l,c = nextCell(l,c,n)
		id += 1
	end
	mcCell = [l, c]	# Coordinates of the most constrained cell
	mcValues = possibleValues(t,l,c,nord,sud,ouest,est)	
	## ===== On répertorie les valeurs possibles pour chaque case ===== ##
	id = 1
	while id <= n*n && size(mcValues, 1)  != 0
		if t[l, c] == 0
			values[l,c] = possibleValues(t, l, c, nord, sud, ouest, est)
			if size(values[l,c], 1) < size(mcValues, 1)
				mcValues = values[l,c]
				mcCell = [l, c]
			end
		end
		l,c = nextCell(l,c,n)
		id += 1
	end
	## =================================================================== ##
	
	it = 0
	## Tant que la grille n'est pas remplie et qu'elle est toujours valide ##
    while gridStillFeasible && filledCases < n*n && it < maxit
		
		## ======== On vérifie que la grille est toujours faisable ======== ##
		if size(mcValues,1) == 0 && t[mcCell[1],mcCell[2]] == 0
			gridStillFeasible = false
		## ================================================================ ##
		else ## ================= La grille est faisable ================= ##
			newValue = ceil.(Int, rand() * size(mcValues, 1))
			newTest = mcValues[rem(newValue, size(mcValues, 1)) + 1]
			gridStillFeasible = false
			## ======= On teste les valeurs possibles de la mcCell ======= ##
			id = 1
			while !gridStillFeasible && id <= size(mcValues, 1)
				t[mcCell[1], mcCell[2]] = newTest
				if isGridFeasible(t, nord, sud, ouest, est)
					push!(coupsJoues,(mcCell,newTest))
					filledCases += 1
					gridStillFeasible = true
				else
					t[mcCell[1], mcCell[2]] = 0
					newValue += 1
					newTest = mcValues[rem(newValue, size(mcValues, 1)) + 1]
					filter!(x->x!=t[mcCell[1], mcCell[2]],values[mcCell[1], mcCell[2]])
				end
				id += 1
			end
			## ========================================================== ##
			if !gridStillFeasible && id > size(mcValues,1) ## == On n'a trouvé aucune valeur ok == ##
				## ========== On veut annuler le dernier choix ========== ##
				if size(coupsJoues,1) > 0
					cell,v = coupsJoues[end]
					t[cell[1],cell[2]] = 0
					filledCases -= 1
					filter!(x->x!=v,values[cell[1],cell[2]])
					gridStillFeasible = true
				else
					gridStillFeasible = false
				end
			end
			## ========= On prend la première cellule nulle trouvée ========== ##
			id = 1
			while !(filledCases == n*n) && t[l,c] != 0 && id < n*n
				l,c = nextCell(l,c,n)
				id += 1
			end
			mcCell = [l, c]	# Coordinates of the most constrained cell
			mcValues = possibleValues(t,l,c,nord,sud,ouest,est)	
			## =================== On recherche la mcCell ================ ##
			id = 1
			while !(filledCases == n*n) && id <= n*n && size(mcValues, 1)  != 0
				if t[l, c] == 0
					if values[l,c] == nothing
					elseif size(values[l,c], 1) < size(mcValues, 1)
						mcValues = values[l,c]
						mcCell = [l, c]
					end
				end
				l,c = nextCell(l,c,n)
				id += 1
			end
			## =========================================================== ##
		end
		it += 1
	end
	if it == maxit
		return t, false
	else
		return t, gridStillFeasible
	end
end

"""
put the easy values in t
"""
function initialize(t,nord,sud,ouest,est)
	#println("----- Initialization -----")
	n = size(t,1)
	filledCases = []
	for i in 1:n
		if ouest[i] == n
			for j in 1:n
				t[i,j] = j
				push!(filledCases,[i,j])
			end
		elseif ouest[i] == 1
			t[i,1] = n
			push!(filledCases,[i,1])
			if est[i] == 2
				t[i,n] = n-1
				push!(filledCases,[i,n])
			end
		end
		if est[i] == n
			for j in 1:n
				t[i,j] = n-j+1
				push!(filledCases,[i,j])
			end
		elseif est[i] == 1
			t[i,n] = n
			push!(filledCases,[i,n])
			if ouest[i] == 2
				t[i,1] = n-1
				push!(filledCases,[i,1])
			end
		end
		if nord[i] == n
			for j in 1:n
				t[j,i] = j
				push!(filledCases,[j,i])
			end
		elseif nord[i] == 1
			t[1,i] = n
			push!(filledCases,[1,i])
			if sud[i] == 2
				t[n,i] = n-1
				push!(filledCases,[n,i])
			end
		end
		if sud[i] == n
			for j in 1:n
				t[j,i] = n-j+1
				push!(filledCases,[j,i])
			end
		elseif sud[i] == 1
			t[n,i] = n
			push!(filledCases,[n,i])
			if nord[i] == 2
				t[1,i] = n-1
				push!(filledCases,[1,i])
			end
		end
	end
	return size(unique(filledCases),1)
end

function nextCell(l,c,n)         
	if c < n
		c += 1
	else
		if l < n
			l += 1
			c = 1
		else
			l = 1
			c = 1
		end
	end
	return l,c
end



"""
Test if cell (l, c) can be assigned value v

Arguments
- t: array of size n*n with values in [0, n] (0 if the cell is empty)
- l, c: considered cell
- v: value considered

Return: true if t[l, c] can be set to v; false otherwise
"""
function isValid(t::Array{Int64, 2}, l::Int64, c::Int64, v::Int64, nord, sud, ouest, est)
	n = size(t, 1)
	if t[l,c] > 0
		return false
	end
    isValid = true
    # Test if v appears in column c
    i = 1
    while isValid && i <= n
        if i != l && t[i, c] == v
			# println("t[",i,",",c,"] = ",v,"\tligne")
            isValid = false
        end
        i += 1
    end
    # Test if v appears in line l
    j = 1
    while isValid && j <= n
        if j!=c && t[l, j] == v
		# println("t[",l,",",j,"] = ",v)
            isValid = false
        end
        j += 1
    end
	
    # Test if the add of v still fits the constraints
	t[l,c] = v
	
	nordVisibles = 0
	sudVisibles = 0
	ouestVisibles = 0
	estVisibles = 0
	
	nordMaxVisibles = 0
	sudMaxVisibles = 0
	ouestMaxVisibles = 0
	estMaxVisibles = 0
	
	nordTowerMax = 0
	sudTowerMax = 0
	ouestTowerMax = 0
	estTowerMax = 0
	
	if isValid
		if t[1,c] >= 0
			nordMaxVisibles += 1
			nordTowerMax = t[1,c]
			if t[1,c] > 0
				nordVisibles += 1
			end
		end
		if t[n,c] >= 0
			sudMaxVisibles += 1
			sudTowerMax = t[n,c]
			if t[n,c] > 0
				sudVisibles += 1
			end
		end
		if t[l,1] >= 0
			ouestMaxVisibles += 1
			ouestTowerMax = t[l,1]
			if t[l,1] > 0
				ouestVisibles += 1
			end
		end
		if t[l,n] >= 0
			estMaxVisibles += 1
			estTowerMax = t[l,n]
			if t[l,n] >0
				estVisibles += 1
			end
		end
	end
	
	i = 2
	while isValid && i<=n
		if nordTowerMax < 5 && (t[i,c] == 0 || t[i,c] > nordTowerMax)
			nordMaxVisibles += 1
			if t[i,c] > nordTowerMax
				nordVisibles += 1
				nordTowerMax = t[i,c]
			end

		end
		if sudTowerMax < 5 && (t[n-i+1,c] == 0 || t[n-i+1,c] > sudTowerMax)
			sudMaxVisibles += 1
			if t[n-i+1,c] > sudTowerMax
				sudVisibles += 1
				sudTowerMax = t[n-i+1,c]
			end
		end

		if ouestTowerMax < 5 && (t[l,i] == 0 || t[l,i] > ouestTowerMax)
			ouestMaxVisibles += 1
			if t[l,i] > ouestTowerMax
				ouestVisibles += 1
				ouestTowerMax = t[l,i]
			end
		end
		if estTowerMax < 5 && (t[l,n-i+1] == 0	|| t[l,n-i+1] > estTowerMax)
			estMaxVisibles +=1
			if t[l,n-i+1] > estTowerMax
				estVisibles += 1
				estTowerMax = t[l,n-i+1]
			end
		end
		i += 1
	end

	if isValid && (nordVisibles>nord[c] || sudVisibles>sud[c] || ouestVisibles>ouest[l] || estVisibles>est[l])
		# println("here")
		isValid = false
	elseif isValid && (nordMaxVisibles<nord[c] || sudMaxVisibles<sud[c] || ouestMaxVisibles<ouest[l] || estMaxVisibles<est[l])
		# println("there")
		isValid = false
	end
	t[l,c] = 0
    return isValid 
end


function possibleValues(t::Array{Int, 2}, l::Int64, c::Int64, nord, sud, ouest, est)
	values = []
    for v in 1:size(t, 1)
	# println("v=",v)
        if isValid(t, l, c, v, nord, sud, ouest, est)
			# println("isValid(t,", l,",", c,",", v,")")
			values = append!(values, v)
		else
			# println("! isValid(t,", l,",", c,",", v,")")
		end
    end
    return values
end


function isGridFeasible(t::Array{Int64, 2}, nord, sud, ouest, est)
    n = size(t, 1)
	copyT = copy(t)
    isFeasible = true
    l = 1
    c = 1
    while isFeasible && l <= n
        if copyT[l, c] == 0
            feasibleValueFound = false
            v = 1
            while !feasibleValueFound && v <= n
                if isValid(copyT, l, c, v, nord, sud, ouest, est)
					feasibleValueFound = true
                end
                v += 1
            end
            if !feasibleValueFound
                isFeasible = false
            end 
        end 
        
		# Go to the next cell
        if c < n
            c += 1
        else
            l += 1
            c = 1
        end
    end
    return isFeasible
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
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global resolutionTime = -1

    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder))
        println("-- Resolution of ", file)
        nord,sud,ouest,est = readInputFile(dataFolder * file)
        
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
					println("resolutionMethod[methodId] == cplex")
                    # Solve it and get the results
                    x, isOptimal, resolutionTime = cplexSolve(nord,sud,ouest,est)
                    # If a solution is found, write it
                    if isOptimal
						writeSolution(fout,x)
					end

                # If the method is one of the heuristics
                else
					println("resolutionMethod[methodId] == heuristique")
                    isSolved = false
                    solution = []

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 10
                        x, isOptimal  = heuristicSolve(nord,sud,ouest,est)
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
            println(resolutionMethod[methodId], " time: " * string(round(resolutionTime, sigdigits=2)) * "s\n")
        end         
    end 
end

generateDataSet()
solveDataSet()

# nord,sud,ouest,est = generateInstance(3)
# saveInstance(nord,sud,ouest,est,"instance_t3_1.txt")

# filename = "./data/instance_t5_1.txt"
# nord,sud,ouest,est = readInputFile(filename)

# displayGrid(nord,sud,ouest,est)

# println("====== Solution avec CPLEX ======")
# x, isOptimal, resolutionTime = cplexSolve(nord,sud,ouest,est)
# println("optimal: ", isOptimal)
# println("time: ", resolutionTime)
# displaySolution(x,nord,sud,ouest,est)

# println("== Solution avec l'heuristique ==")
# start = time()
# t, isOptimal = heuristicSolve(nord,sud,ouest,est)
# resolutionTime = time() - start
# println("optimal: ", isOptimal)
# println("time: ", resolutionTime)
# displaySolution(t,nord,sud,ouest,est)

