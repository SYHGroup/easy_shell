for i in $(seq -w 1 10)
do
#ffmpeg -i Kono_Subarashii_Sekai_ni_Shukufuku_wo__-_${i}__BD_1280x720_AVC_AACx2_.mp4 -vf "ass=_Kono_Subarashii_Sekai_ni_Shukufuku_o___${i}__BDRIP__1080P__H264_FLAC_.sc_KissSubFZSD.ass" ${i}.mp4 &
ffmpeg -i Kono_Subarashii_Sekai_ni_Shukufuku_wo__2_-_${i}__BD_1280x720_AVC_AACx2_.mp4 -vf "ass=_KissSub&FZSD&Xrip__Kono_Subarashii_Sekai_ni_Shukufuku_o__2__BDrip__${i}__1080P__HEVC_Main10_.sc.ass" ${i}.mp4
done
