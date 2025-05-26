#! bin/bash

#introduction: find  filter suitable blast hits for LCA in eDNAFlow
# Copy right to Ms.SUN Ruixian from Prof. Charmaine YUNG lab, Department of Ocean Science, HKUST
#logic:
#1. if qseqid =1 (only have 1 hit), keep it.
#2. if qseqid > 1 (have more than 1 hit), if all the hits have the same taxid, keep them.
#3. if qseqid > 1 (have more than 1 hit), and if hits have different taxids, keep the highest pident score.

#说明
#逻辑：
#1. 如果只有一个qseqid,直接保留
#2. 如果不只有一个qseqid, 那么看taxid：
##2.1 如果taxid都一样（只有一种taxid)，不论pident是多少，一并保留。
##2.2 如果taxid有不一样的（出现大于一种taxid），看pident, 保留分数最高的。（如果有并列最高者，不管taxid是否一样也会一并保留）

#建两个文件夹过后会删掉
mkdir -p process
mkdir -p filtered

#！！！！！！！！cat这里放你的input文件！！！！！！！！！！！！！
#说明：请手动删掉stitle这一列 manually delete the column 'stitle' before run this shell
#列的顺序并不会影响结果，一定要有qseqid, taxid, pident这三列，其余无所谓 the order of column does not matter. three necessary column :qseqid, taxid, pident
#输入的文件为tsv格式（tab分割） the input file is delimited with tabs.
cat "/home/SharedFolder/eDNA_MiFish/blast98.5_all_test.txt" >process/input.tsv

#第一步，提取所有的qseqid
cat process/input.tsv |
    csvtk cut -f 1 -t |
    csvtk uniq -o process/qseqid_list_1.txt
sed '1d' process/qseqid_list_1.txt >process/qseqid_list_2.txt

#进入循环，把每一个qseqid都单独分出来一个文件，然后按照上面的逻辑去筛
#所以通过筛选的行会被扔进filtered这个文件夹
while read p; do
    csvtk grep -f 1 -p $p -t process/input.tsv -o process/''"$p"'_raw.tsv'
    if [ $(csvtk nrow -t process/''"$p"'_raw.tsv') -eq 1 ]; then
        cp process/''"$p"'_raw.tsv' filtered/''"$p"'_filtered.tsv'
    fi
    if [ $(csvtk nrow -t process/''"$p"'_raw.tsv') -gt 1 ]; then
        if [ $(csvtk freq process/''"$p"'_raw.tsv' -t -f staxids | wc -l) -eq 1 ]; then
            cp process/''"$p"'_raw.tsv' filtered/''"$p"'_filtered.tsv'
        else
            max_pident=$(csvtk sort process/''"$p"'_raw.tsv' -k pident:n -t |
                csvtk cut -f pident -t |
                tail -n 1)
            csvtk filter process/''"$p"'_raw.tsv' -f "pident=$max_pident" -t \
                -o filtered/''"$p"'_filtered.tsv'
        fi
    fi
done <process/qseqid_list_2.txt

#最后合并一下通过筛选的小可爱然后把过程文件删掉
csvtk concat filtered/*.tsv -t -o filtered_result.tsv
rm -r -f process
rm -r -f filtered
