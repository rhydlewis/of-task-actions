#!/bin/bash

. workflowHandler.sh

THEME=$(getPref theme 1)

OFOC="com.omnigroup.OmniFocus"
if [ ! -d "$HOME/Library/Caches/$OFOC" ]; then OFOC=$OFOC.MacAppStore; fi

ZONERESET=$(date +%z | awk '
{if (substr($1,1,1)!="+") {printf "+"} else {printf "-"} print substr($1,2,4)}') 
YEARZERO=$(date -j -f "%Y-%m-%d %H:%M:%S %z" "2001-01-01 0:0:0 $ZONERESET" "+%s")
START="($YEARZERO + t.dateToStart)";
DUE="($YEARZERO + t.dateDue)";
DONE="($YEARZERO + t.dateCompleted)";

START_OF_DAY=$(date -v0H -v0M -v0S +%s)
TODAY=$(date "+%Y-%m-%d")

SQL="SELECT t.persistentIdentifier, t.name, strftime('%Y-%m-%d %H:%M',${START}, 'unixepoch'), strftime('%Y-%m-%d %H:%M',${DUE}, 'unixepoch'), t.isDueSoon, t.isOverdue, t.flagged, t.repetitionMethodString, t.repetitionRuleString, c.name, p.name FROM Task t, (Task tt left join ProjectInfo pp ON tt.persistentIdentifier = pp.pk ) p, Context c WHERE t.blocked = 0 AND t.childrenCountAvailable = 0 AND t.blockedByFutureStartDate = 0 AND t.containingProjectInfo = p.pk AND t.context = c.persistentIdentifier AND $DONE > $START_OF_DAY"

OLDIFS="$IFS"
IFS='
'
TASKS=$(sqlite3 ${HOME}/Library/Caches/${OFOC}/OmniFocusDatabase2 "${SQL}")

for T in ${TASKS[*]}; do
  TID=${T%%|*}
  REST=${T#*|}
  TNAME=${REST%%|*}
  REST=${REST#*|}
  TSTART=${REST%%|*}
  REST=${REST#*|}
  TDUE=${REST%%|*}
  REST=${REST#*|}
  TSOON=${REST%%|*}
  REST=${REST#*|}
  TOVERDUE=${REST%%|*}
  REST=${REST#*|}
  TFLAGGED=${REST%%|*}
  REST=${REST#*|}
  TREPTYPE=${REST%%|*}
  REST=${REST#*|}
  TREPRULE=${REST%%|*}
  REST=${REST#*|}
  TCONTEXT=${REST%%|*}
  TPROJECT=${REST##*|}

  addResult "${TID}" "${T}|1" "${TNAME} (${TPROJECT})" "Start: ${TSTART}  |  Due: ${TDUE}  |  Context: ${TCONTEXT}" "img/detail/${THEME}/done.png" "yes"
done

IFS="$OLDIFS"

getXMLResults

