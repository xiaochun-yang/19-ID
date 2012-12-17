#!/usr/bin/env python

import cPickle as pickle
g = open('DISTL_pickle','rb')
Spotfinder = pickle.load(g)

for key in Spotfinder.pd['osc_start'].keys():
  image = Spotfinder.images[key]
  print
  print "%21s : %s"%("File",Spotfinder.pd['template'].replace('###','%03d'%key))
  print "%21s : %6d"%("Spot Total",image['N_spots_total'])
  print "%21s : %6d"%("Good Bragg Candidates",image['N_spots_inlier'])
  print "%21s : %4d"%("Ice Rings",image['ice-ring_impact'])
  print "%21s : %6.2f"%("Method 1 Resolution",image['distl_resolution'])
  print "%21s : %6.2f"%("Method 2 Resolution",image['resolution'])
  
