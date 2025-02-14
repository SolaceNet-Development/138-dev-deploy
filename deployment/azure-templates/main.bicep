targetScope = 'subscription'

param regions array = [
  'australiaeast'
  'germanywestcentral'
  'centralindia'
  'uaenorth'
  'brazilsouth'
  'francecentral'
  'uksouth'
  'japaneast'
  'southeastasia'
  'israelcentral'
  'polandcentral'
  'norwayeast'
  'spaincentral'
  'italynorth'
]

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = [for region in regions: {
  name: 'rg-hyperledger-${region}'
  location: region
  tags: {
    Environment: 'Production'
    Network: 'Hyperledger'
  }
}]

module networkDeployment 'region-deployment.json' = [for (region, i) in regions: {
  name: 'network-${region}'
  scope: rg[i]
  params: {
    location: region
    vmSize: 'Standard_D8s_v3'
  }
}]
