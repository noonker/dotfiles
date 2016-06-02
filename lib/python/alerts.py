import subprocess
from time import sleep 

def plsbeep(delay=0):
    sleep(delay)
    subprocess.call('echo -e "\a"', shell=True)
