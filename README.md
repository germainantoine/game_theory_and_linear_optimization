Projet_RO203
=================
 ## Jeu 1: Towers
 ## Jeu 2: Singles
  ### Heuristique
  
**heuristicSolve(grille) :** essaye heurisqucSlove1 jusqu’à ce qu’une solution admissible soit trouvée,

**heuristicSolve1(grille) :** génère un vecteur y qui contient des cases noires qui masquent les doublons  sur les lignes et les colones de la grille. Les choix sont faits aléatoirement. Renvoie b==1 ssi la grille ainsi trouvée est connexe.

**liste_doublons(grille) :** génère une liste de liste de coordonnés de doublons. ex : [[(i,j),(i,l),(i,k)],[…]] si sur la ligne i, les élements aux positions j k et l sont identiques

**doublon_ligne(i,grille,val) :** mémorise dans une liste les couples de coordonnées de valeur val à la ligne i. s’il y en a plus que 2, retourne une telle liste.

**doublon_colone(j,grille,val) :** mémorise dans une liste les couples de coordonnées de valeur val à la colone j. s’il y en a plus que 2, retourne une telle liste.

**random_choose_in_list(l) :** retourne un élement aléatoire de l et son indice

**supprimer_doublons_i_j(liste,i,j):** supprimer dans une liste de couples de coordonnées les couples de coordonnées (i,j)

**liste_cases_admissibles(y,x) :** une case est admissible (à être noircie) si elle est entourée de cases blanches. Cette fonction renvoie toutes les cases admissibles de x(x liste de couples de coordonées) en fonction des cases noires déjà coloriées contenues dans y.

**supprimer_doubons_de_x(grille,y,x) :** essaye de noircir les doublons de x tel que la grille reste connexe. envoie cases_noires une liste des coordonnées des cases nouvellement noircies s'il y arrive en moins de 3n tentatives, et renvoie [] sinon. y a été mis à jour.

**Pseudo-code:**
--------------------
    |x liste de couples de coordonnées qui sont les doublons d’une ligne ou d’une colone. On essaye de noircir tous ceux-ci sauf 1.
     |tant que x contient plusieurs élements :
      |on liste les cases admissibles dans x(couples de x qu’il est possible de noircir)
      |s’il y en a :
       |on choisit une case au hasard à noircir dans cases admissibles
       |si la grille reste connexe :
        |on ajoute cette case aux nouvelles cases noires
        |on supprime cette case choisie de x
        |on met à jour les cases admissibles
      |sinon on recommence avec une autre case choisie au hasard.
     |Si après au plus 3n tentatives on a bien x de taille 1 (on a noircie tous les autres doublons de cette ligne ou colone) on retourne les cases noires trouvées. 
    |Sinon c’est probablement qu’il n’est pas possible de noircir x et on renvoie [].
