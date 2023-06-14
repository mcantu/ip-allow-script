#!/bin/bash

endCursor=""
hasNextPage=true

while [ "$hasNextPage" = true ]
do
    output=$(gh api graphql -f enterpriseName='enterpriseSlug' -f afterCursor="$endCursor" -f query='
    query getEnterpriseIpAllowList($enterpriseName: String! $endCursor: String) {
      enterprise(slug: $enterpriseName) {
        ownerInfo {
          ipAllowListEntries(first: 100, after: $endCursor) {
            nodes {
              id
              allowListValue
              name
              isActive
              createdAt
              updatedAt
            }
            pageInfo {
              endCursor
              hasNextPage
            }
          }
        }
      }
    }')

    length=$(echo $output | jq -r '.data.enterprise.ownerInfo.ipAllowListEntries.nodes | length')
    endCursor=$(echo $output | jq -r '.data.enterprise.ownerInfo.ipAllowListEntries.pageInfo.endCursor')
    hasNextPage=$(echo $output | jq -r '.data.enterprise.ownerInfo.ipAllowListEntries.pageInfo.hasNextPage')

    for (( i=0; i<$length; i++ ))
    do
      isActive=$(echo $output | jq -r ".data.enterprise.ownerInfo.ipAllowListEntries.nodes[$i].isActive")
      
      if [ "$isActive" = "false" ]
      then
        allowListValue=$(echo $output | jq -r ".data.enterprise.ownerInfo.ipAllowListEntries.nodes[$i].allowListValue")
        entry_id=$(echo $output | jq -r ".data.enterprise.ownerInfo.ipAllowListEntries.nodes[$i].id")
        name=$(echo $output | jq -r ".data.enterprise.ownerInfo.ipAllowListEntries.nodes[$i].name")

        gh api graphql -f allow_list_value="$allowListValue" -f entry_id="$entry_id" -f name="$name" -f query='
        mutation ($allow_list_value: String! $name: String! $entry_id: ID!) { 
          updateIpAllowListEntry(input: { allowListValue: $allow_list_value ipAllowListEntryId: $entry_id name: $name isActive: true }) { 
              ipAllowListEntry {
                id
                allowListValue
                name
                isActive
              }
           } 
        }'

        sleep 5
      fi
    done
done
