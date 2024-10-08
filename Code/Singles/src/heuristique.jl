include("generation.jl")


#génère un vecteur y qui contient des cases noires qui masquent les doublons  sur les lignes et les colones de la grille. Les choix sont faits aléatoirement. Renvoie b==1 ssi la grille ainsi trouvée est connexe.

function heuristicSolve1(grille)
	n=size(grille,1)
	y=ones(Int,n,n)
	kv=0
	cases_noires=[]
	doublons=liste_doublons(grille)
	while (doublons!=[])&&(kv<=3*n*n)
		kv+=1
		x,kx=random_choose_in_list(doublons)
		cases_noires=supprimer_doubons_de_x(grille,y,x)
		if cases_noires!=[]
			deleteat!(doublons,kx)
		end
	end
	# println("doublons",doublons)
	#displaySolution(grille,y)
	if doublons==[]
		b=1
		return b,y
	else 
		b=0
		return b,ones(Int,n,n)
	end
end 

#génère une liste de liste de coordonnés de doublons. ex : [[(i,j),(i,l),(i,k)],[…]] si sur la ligne i, les élements aux positions j k et l sont identiques

function liste_doublons(grille)
	n = size(grille,1)
	doublons=[]
	for i in 1:n
		for val in 1:n
			if doublon_ligne(i,grille,val)!=[]
				append!(doublons,[doublon_ligne(i,grille,val)])
			end
		end
	end
	for j in 1:n
		for val in 1:n
			if doublon_colone(j,grille,val)!=[]
				append!(doublons,[doublon_colone(j,grille,val)])
			end
		end
	end
	
	return doublons
end

#mémorise dans une liste les couples de coordonnées de valeur val à la ligne i. s’il y en a plus que 2, retourne une telle liste.
function doublon_ligne(i,grille,val)
	n = size(grille,1)
	mem=[]
	for j in 1:n
		if grille[i,j]==val
			append!(mem,[(i,j)])
		end
	end
	if size(mem,1)>1
		return mem
	else
		return []
	end
end

#mémorise dans une liste les couples de coordonnées de valeur val à la colone j. s’il y en a plus que 2, retourne une telle liste.
function doublon_colone(j,grille,val)
	n = size(grille,1)
	mem=[]
	for i in 1:n
		if grille[i,j]==val
			append!(mem,[(i,j)])
		end
	end
	if size(mem,1)>1
		return mem
	else
		return []
	end
end

#retourne un élement aléatoire de l et son indice
function random_choose_in_list(l)
	n=size(l,1)
	i=ceil.(Int, n * rand())
	return l[i],i
end

#supprimer dans une liste de couples de coordonnées les couples de coordonnées (i,j) 
function supprimer_doublons_i_j(liste,i,j)
	s=size(liste,1)
	for k=1:s
		if liste[k]==(i,j)
			deleteat!(liste,k)
			break
		end
	end
	return liste
end

#une case est admissible (à être noircie) si elle est entourée de cases blanches. Cette fonction renvoie toutes les cases admissibles de x(x liste de couples de coordonées) en fonction des cases noires déjà coloriées contenues dans y. 
function liste_cases_admissibles(y,x)
	n=size(y,1)
	
	cases_admissibles=[]
	
	for (i,j) in x
		if case_entouree_de_case_blanche(y,i,j)==1
			append!(cases_admissibles,[(i,j)])
		end
	end
	return cases_admissibles
end

#essaye de noircir les doublons de x tel que la grille reste connexe. envoie cases_noires une liste des coordonnées des cases nouvellement noircies s'il y arrive en moins de 3n tentatives, et renvoie [] sinon. y a été mis à jour.
function supprimer_doubons_de_x(grille,y,x)
	cases_noires=[]
	n=size(y,1)
	cont=0
	while ((size(x,1)>1)&&(cont<=3*n*n))
		cont=cont+1
		cases_admissibles=liste_cases_admissibles(y,x)
		if cases_admissibles!=[]
		(i,j),k=random_choose_in_list(cases_admissibles)
		y[i,j]=0
			if is_graph_connexe(y) 
				append!(cases_noires,[(i,j)])
				supprimer_doublons((i,j),x)
				cases_admissibles=liste_cases_admissibles(y,x)
			else
				y[i,j]=1
				
			end
		end
	end
	if size(x,1)==1
		return cases_noires
	else
		return []
	end
end

