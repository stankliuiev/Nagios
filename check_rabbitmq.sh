#!/bin/sh
#set -x
#simple script to check some rabbitmq metrics from 15692 port
#Stan Kliuiev 2022-11-08
RESULT=0

# exit statuses recognized by Nagios
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3


wget -O- -q  someip:15692/metrics > /tmp/metrics

unroutable_returned=$(grep '^rabbitmq_channel_messages_unroutable_returned_total' /tmp/metrics | sed "s/^[^ ]* //")
uptime_seconds=$(grep '^rabbitmq_erlang_uptime_seconds' /tmp/metrics | sed "s/^[^ ]* //"|cut -d '.' -f 1)
disk_space_available=$(grep '^rabbitmq_disk_space_available_bytes' /tmp/metrics | sed "s/^[^ ]* //")
used_memory=$(grep '^erlang_vm_memory_processes_bytes_total{usage="used"}' /tmp/metrics | sed "s/^[^ ]* //")
free_memory=$(grep '^erlang_vm_memory_processes_bytes_total{usage="free"}' /tmp/metrics | sed "s/^[^ ]* //")
rabbitmq_queue_consumers=$(grep '^rabbitmq_queue_consumers' /tmp/metrics | sed "s/^[^ ]* //")

if [ "$unroutable_returned" -lt 1 ]
then
    if [ "$RESULT" -eq 0 ]
    	then
	RESULT=0 ; unroutable_returned_var=$(echo "OK rabbitmq_channel_messages_unroutable_returned_total = $unroutable_returned")
    fi
elif
    [ $unroutable_returned -ge 1 ]
then    
    if [ "$RESULT" -lt 2 ]
        then
        RESULT=2 ; unroutable_returned_var=$(echo "CRITICAL a queue has unroutable messages rabbitmq_channel_messages_unroutable_returned_total = $unroutable_returned")
    fi
fi


if [ $uptime_seconds -gt 3600 ]
then
    if [ "$RESULT" -eq 0 ]
        then
        RESULT=0 ; uptime_seconds_var=$(echo "OK rabbitmq_erlang_uptime_seconds = $uptime_seconds")
    fi
elif
    [ $uptime_seconds -gt 1500 ]
then    
    if [ "$RESULT" -lt 1 ]
        then
        RESULT=1 ; uptime_seconds_var=$(echo "WARNING rabbitmq_erlang_uptime_seconds = $uptime_seconds")
    fi
else 
    [ $uptime_seconds -lt 1500 ]
    if [ "$RESULT" -lt 2 ]
        then
        RESULT=2 ; uptime_seconds_var=$(echo "CRITICAL rabbitmq_erlang_uptime_seconds = $uptime_seconds")
    fi
fi


if [ $disk_space_available -gt 53687091200 ]
then
    if [ "$RESULT" -eq 0 ]
        then
        RESULT=0 ; disk_space_available_var=$(echo "OK rabbitmq_disk_space_available_bytes = $disk_space_available") 
    fi
elif
    [ $disk_space_available -gt 21474836480 ]
then    
    if [ "$RESULT" -lt 1 ]
    	then
        RESULT=1 ; disk_space_available_var=$(echo "WARNING rabbitmq_disk_space_available_bytes = $disk_space_available")
    fi
else 
    [ $disk_space_available -lt 21474836480 ]
    if [ "$RESULT" -lt 2 ]
        then
        RESULT=2 ; disk_space_available_var=$(echo "CRITICAL rabbitmq_disk_space_available_bytes = $disk_space_available")
    fi
fi

if [ $used_memory -lt 629145600 ]
then
    if [ "$RESULT" -eq 0 ]
        then
        RESULT=0 ; used_memory_var=$(echo "OK erlang_vm_memory_processes_bytes_total{usage="used"} = $used_memory")
    fi
elif
    [ $used_memory -gt 629145600 ]
then    
    if [ "$RESULT" -lt 1 ]
        then
        RESULT=1 ; used_memory_var=$(echo "WARNING erlang_vm_memory_processes_bytes_total{usage="used"} = $used_memory")
    fi
else 
    [ $used_memory -gt 838860800 ]
    if [ "$RESULT" -lt 2 ]
        then
        RESULT=2 ; used_memory_var=$(echo "CRITICAL erlang_vm_memory_processes_bytes_total{usage="used"} = $used_memory")
    fi
fi

if [ $free_memory -gt 100 ]
then
    if [ "$RESULT" -eq 0 ]
        then
        RESULT=0 ; free_memory_var=$(echo "OK erlang_vm_memory_processes_bytes_total{usage="free"} = $free_memory")
    fi
fi

if [ $rabbitmq_queue_consumers -gt 0 ]
then
    if [ "$RESULT" -eq 0 ]
        then
        RESULT=0 ; rabbitmq_queue_consumers_var=$(echo "OK rabbitmq_queue_consumers = $rabbitmq_queue_consumers")
    fi
elif [ $rabbitmq_queue_consumers -eq 0 ]
then
    if [ "$RESULT" -lt 2 ]
        then
        RESULT=2 ; rabbitmq_queue_consumers_var=$(echo "CRITICAL Rabbitmq has no consumers rabbitmq_queue_consumers = $rabbitmq_queue_consumers")
    fi
fi


case "$RESULT" in
        0)              echo "OK: rabbitmq works without issues, $unroutable_returned_var, $uptime_seconds_var, $disk_space_available_var, $used_memory_var, $free_memory_var, $rabbitmq_queue_consumers_var"; exit $OK;;
        1)              echo "WARNING: some limits are close to critical, $unroutable_returned_var, $uptime_seconds_var, $disk_space_available_var, $used_memory_var, $free_memory_var, $rabbitmq_queue_consumers_var"; exit $WARNING;;
        2)              echo "CRITICAL: action required, $unroutable_returned_var, $uptime_seconds_var, $disk_space_available_var, $used_memory_var, $free_memory_var, $rabbitmq_queue_consumers_var"; exit $CRITICAL;;
        *)              echo "UNKNOWN something went wrong :("$UNKNOWN;;
esac

exit $RESULT
