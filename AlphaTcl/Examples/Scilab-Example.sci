// Scilab-Example.sci
//
// Included in the Alpha distribution as an example of the Scil mode.
// Scil mode is part of the standard Alpha distribution.
//
// Scilab is a scientific software package for numerical computations in a 
// user-friendly environment.  It features:
// 
// Elaborate data structures (polynomial, rational and string matrices, lists,
// 	multivariable linear systems,...).
// Sophisticated interpreter and programming language with Matlab-like syntax. 
// Hundreds of built-in math functions (new primitives can easily be added). 
// Stunning graphics (2d, 3d, animation). 
// Open structure (easy interfacing with Fortran and C via online dynamic link). 
// Many built-in libraries: 
//                                        
//    ¥	Linear Algebra (including sparse matrices, Kronecker form, 
// 	ordered Schur,...). 
//    ¥	Control (Classical, LQG, H-infinity,...). 
//    ¥	Package for LMI (Linear Matrix Inequalities) optimization. 
//    ¥	Signal processing. 
//    ¥	Simulation (various ode's, dassl,...). 
//    ¥	Optimization (differentiable and non-differentiable, LQ solver). 
//    ¥	Scicos, an interactive environment for modeling and simulation of 
// 	hybrid systems. 
//    ¥	Metanet (network analysis and optimization). 
//                                 
// Symbolic capabilities through Maple interface. 
// Parallel Scilab. 
// 
// Additional information about Scilab (the source of this file) can be found at:
// 
// 	<http://www-rocq.inria.fr/scilab/>
//

function [path] = PathToCmapUtility()
  // put here the path to your CmapUtility directory 
  path = ""
  
function [fichier] = DefaultCmapFile()
  path =  PathToCmapUtility()
  fichier = path+"CmapForms.cmp" 
  
function [cmap] = colormap(a1,        a2,     a3)
  //                      (cmap_name, nb_col, cmap_file)
  //
  //  The main function to get a colormap from a Cmap forms file
  //
  //  cmap_name : (string) the name of a cmap (form)
  //  nb_col    : (integer) the nb of color for the resulting cmap
  //  cmap_file : (string) file to read so as to find the cmap_name cmap (form)

  //  authorized calling sequences :
  //  (cmap_name), (cmap_name, nb_col), (cmap_name, nb_col, cmap_file) 
  default_nb_col = 64 ;

  nb_col = default_nb_col ; cmap_file =  DefaultCmapFile()
  [lhs ,rhs] = argn(0)

  select rhs     // some cautions for bad calling (but not complete... in
                 // particular it is assumed that all arg are scalars)
  case 1
    if typeof(a1) == "string" then
      cmap_name = a1
    else
      error(" colormap : first argument may be a string (colormap name)")      
    end
  case 2
    if typeof(a1) == "string" & typeof(a2) == "constant" then
      cmap_name = a1; nb_col = a2
    else
      error(" colormap : arg 1 may be a string (colormap name) and arg 2 an integer (nb_colors) ")
    end
  case 3
    if typeof(a1) == "string" & typeof(a2) == "constant" & typeof(a3) == "string" then
      cmap_name = a1; nb_col = a2, cmap_file = a3
    else
      error(" colormap : arg1 may be a string, arg 2 an integer and arg 3 a string ")
    end
  else      
    error(" colormap : bad calling sequence ")
  end          

  [ListCmapf, info] = ReadCmapFormsFile(cmap_file)
  if ~info then
    error(" Problem to read the colormap file "+cmap_file)
  end
  
  trouve = %f ; i = 1
  while ~trouve & (i <= length(ListCmapf))
    if ListCmapf(i).name == cmap_name then
      cmapf =  ListCmapf(i) ; trouve = %t
    else
      i = i+1
    end
  end
  
  if trouve then
    cmap = MakeCmap(cmapf, nb_col)
  else
     write(%io(2)," This colormap doesn''t exist in the file "+cmap_file)
     write(%io(2)," which contains only the following :")
     for i=1:length(ListCmapf)
       write(%io(2),"       "+ListCmapf(i).name)
     end
     cmap = []
   end
    
function [cmap] = CmapUtil(CurrentFile)  
  //
  //   The main function to view and manage some colormaps (forms) files 
  //   and then to build colormaps...
  //   You may also retrieve a scilab colormap (cmap) (a (nc,3) matrix)
  //
  [lhs ,rhs] = argn(0)
  if rhs == 0 then
    CurrentFile = DefaultCmapFile()
  end
  
  path = PathToCmapUtility()
  getf(path+"CmapUtilInternals.sci")  // get all the other funcs
  
  nb_colors = 128
  CmapForm_InitRand()
  //-----------------get a free graphical win and initialise it--------
  win = a_free_gwin()
  xset("window",win)
  xbasc()
  delmenu(win,"File") ; delmenu(win,"2D Zoom") ; delmenu(win,"UnZoom")
  delmenu(win,"3D Rot.")

  //------------------add menus and buttons---------------------------
  addmenu(win,"Previous")
  addmenu(win,"Next")
  addmenu(win,"Create", [ "From this colormap form" ;...
                          "From nothing with a little help of rand" ;...
                          "By transform a colormap in a cmap form "])            
  addmenu(win,"Redraw")
  addmenu(win,"Quit")  
  ajoute_menu_Operations(win,CurrentFile)

  //------------------define actions associated with menus-----------------
  swin = string(win)
  execstr("Previous_"     + swin + '= ""CurrentAction = """"previous""""""')
  execstr("Next_"        + swin + '= ""CurrentAction = """"next""""""') 
  execstr("Create_"      + swin + '=[""CurrentAction = """"create1"""""" ;...
                                     ""CurrentAction = """"create2"""""" ;...
                                     ""CurrentAction = """"create3""""""]')
  execstr("Operations_"  + swin + '=[""CurrentAction = """"marksd"""""" ;...
                                     ""CurrentAction = """"ch_name"""""";...
                                     ""CurrentAction = """"save1""""""  ;...
                                     ""CurrentAction = """"save2""""""  ;...
                                     ""CurrentAction = """"openf""""""  ;...
                                     ""CurrentAction = """"ch_nbcol""""""]')
  execstr("Redraw_"      + swin + '= ""CurrentAction = """"redraw""""""')
  execstr("Quit_"        + swin + '= ""CurrentAction = """"quit""""""')
  CurrentAction = "readCurrentFile"

  while %t    //---- (big...) events loop--------------------------------------
    select CurrentAction
    case "readCurrentFile"
      [ListCmapf, info] = ReadCmapFormsFile(CurrentFile)
      if ~info then
        cmapf =[]
        disp(" Problems to read the file "+CurrentFile+" ...")
        break
      end
      NbCmapf = length(ListCmapf) ; NbCmapf_init = NbCmapf ; Num = 1
      mark = bool2s(ones(1,NbCmapf))   // to mark save/delete
      CurrentAction = "redraw"
    case "next"
       Num = Num + 1 ; if (Num > NbCmapf) then, Num = 1, end
       CurrentAction = "redraw"
    case "previous"
       Num = Num - 1 ; if (Num < 1) then, Num = NbCmapf, end
       CurrentAction = "redraw"
    case "create1"
       [cmapf] = Define_Cmap(ListCmapf(Num)) ; CurrentAction = "insert_in_list"
    case "create2"
       [cmapf] = Define_Cmap() ; CurrentAction = "insert_in_list"
    case "create3"
       [cm, OK] = get_the_cmap()
       if OK then
         cmapf = cmap_to_cmapf(cm) 
         [cmapf] = Define_Cmap(cmapf) ; CurrentAction = "insert_in_list"
       else
         CurrentAction = "nothing"
       end
    case "insert_in_list"
       NbCmapf = NbCmapf + 1 ; Num = NbCmapf ; mark(Num) = %t
       ListCmapf(Num) = cmapf ; ListCmapf(Num).name = "A new with no name"
       CurrentAction = "redraw" ; xset("window",win)  // to set win as the new current gr win
    case "ch_nbcol"
       [nb_colors] = Choix_nb_colors("New number of colors (for colorbar) :", nb_colors)
       CurrentAction = "redraw"
    case "ch_name"
       ListCmapf(Num).name = Get_a_Name("Choose a new name for "+ListCmapf(Num).name)
       CurrentAction = "redrawlight"
    case "marksd"     
       mark(Num) = ~mark(Num)
       CurrentAction = "redrawlight"
    case "save1" 
       FileName = CurrentFile ; CurrentAction = "save"
    case "save2"
       FileName = Get_a_Name("Give a file name") ; CurrentAction = "save"
    case "save"
       [ListCmapf] = saveCmapf(ListCmapf, mark, FileName)
       Num = 1; NbCmapf = length(ListCmapf) ; NbCmapf_init = NbCmapf
       mark = bool2s(ones(NbCmapf,1))
       CurrentAction = "redraw"
    case "openf"
       CurrentFile = xgetfile("*.cmp",title="Choose a Colormap Forms file")
       delmenu(win,"Operations") ; ajoute_menu_Operations(win,CurrentFile)
       CurrentAction = "readCurrentFile"
    case "redraw"
       [cmap, red, green, blue] = ActualiseCmap(ListCmapf(Num), nb_colors)
       CurrentAction = "redrawlight"
    case "redrawlight"
       xbasc()
       xsetech([0 0 1 1],[0 -0.5 1 1])
       PlotLaTotale(ListCmapf(Num), nb_colors, red, green, blue)
       disp_info(ListCmapf(Num).name, mark(Num), NbCmapf, NbCmapf_init, Num)
       CurrentAction = "nothing"
    case "quit"
       cmapf = ListCmapf(Num)
       nb_col = Choix_nb_colors("Choose a number of colors for the selected cmap form", 64)
       cmap = MakeCmap(cmapf, nb_col)    
       break
    end
  end //--- of the (big) events loop-----------------------------------------/
  
  xset("default")
  xdel(win)

  
function [ListCmapf, info] = ReadCmapFormsFile(FileName)
  [unit, err] = file("open", FileName, "old")
  ListCmapf = list()
  if err < 1 then
     info = %t
     n = read(unit,1,1)
     for i=1:n
        ListCmapf(i) = tlist(["CmapForm", "name", "red", "green", "blue"])
        ListCmapf(i)("name") = read(unit,1,1,"(a)")
        for j=3:5
           l = read(unit,1,1)
           x = read(unit,1,l) ; y =  read(unit,1,l)
           ListCmapf(i)(j) = tlist(["ColorIntensity","x","y"], x, y)
        end
     end
     file("close",unit)
  else
     info = %f
  end
  
function [cmap] = MakeCmap(cmapf, nb_colors)
  //   Get a colormap cmap from a colormap form cmapf and
  //   a number of colors nb_colors
  x = linspace(0,1,nb_colors)'
  cmap = [ cmapf("red")*x , cmapf("green")*x , cmapf("blue")*x ]

function [yy] = %ColorInt_m_s(color, xx)
  //   Definition of the operation ColorIntensity * vector
  yy = interpln([color.x ; color.y],xx)'
  yy = min(1, max(0 , yy))
  







