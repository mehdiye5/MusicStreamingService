#echo $1
#echo $2
# 1 number of commits
# 2 which day of the week
# 3 which month
# 4 which day of the month

for k in `seq 1 $1`
do
    git commit --amend --no-edit --date="$2 $3 $4 11:$k:12 2022 -0600"
    git push -f
done