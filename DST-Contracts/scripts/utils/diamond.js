/* eslint-disable */
const getSelectors = (contract) => {
  const signatures = Object.keys(contract.interface.functions)
  return signatures.map((s) => contract.interface.getSighash(s))
}

module.exports = { getSelectors }


