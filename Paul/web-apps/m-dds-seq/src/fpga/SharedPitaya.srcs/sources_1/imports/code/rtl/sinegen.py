tabledepth=input('Enter Number of entries in 2pi:')
tablewidth=input('Enter Number of bits in signed integer:')
angles=range(tabledepth)*2*3.14159/(tabledepth)
print angles
vals=(2.0**(tablewidth-1.0))
