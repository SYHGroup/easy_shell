ls | while read name
do
mv "$name" $(echo $name | tr ' ' '_' | tr '!' '_' | tr '[' '_' | tr ']' '_')
done
