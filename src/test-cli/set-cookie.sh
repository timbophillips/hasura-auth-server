# Extract bookie after login
COOKIE=$(http "$@" --print=h | grep 'Cookie' | cut -d: -f2 | cut -c2-)

echo "Storing the following cookie in .session.json:"
echo  "$COOKIE"

# Create a session file 
cat >.session.json <<-EOF
{
    "headers": {
        "Cookie": "${COOKIE}"
    }
}
EOF

# Remove line endings
sed -i 's/\r//g' .session.json
