import numpy as np
import matplotlib.pyplot as plt

LOG_NAME       = input('Log File Name: ')

dataS = np.loadtxt(LOG_NAME)
plt.figure()
plt.stem(dataS)
plt.grid()

plt.show(block=False)
input('Press Enter to Continue')
plt.close()
