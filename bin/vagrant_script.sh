#!/bin/sh
echo " --> Executing custom shell script in vagrant env"

echo "Hello from $0"
python -V &> /dev/null && python -mplatform
arch
#. ~vagrant/venv/bin/activate 
cd /vagrant && sudo python setup.py test && sudo python setup.py install
/usr/bin/scsqc -c /files/my.conf
echo "------------------------------------------------"
