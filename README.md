# Crowd Fund Escrow

## Dependencies

Before proceeding, install the dependencies:

`yarn install`

## Test

`forge test`

## TODO

- add mechanism to ensure that a milestone cant sit stale for extended time. after X amount of time (maybe specified by creator) the project should time out, and donors should be able to withdraw their funds
- add mechanism to allow project creators to close their project. All state for the project should be saved, but no more state can be updated, and all donors should be able to withdraw. This is also useful incase the creator cannot fullfil a milestone, but want to create a new project with new milestone specs.
- figure out what needs to be done to support account abstraction (ERC4337)
- figure out what needs to be done to support diamond standard proxy contract (ERC2535)
- figure out what needs to be done to support deployment on layer 2 (specifically zksync)
- figure out how to prevent creators from uploading more evidence after a dispute has been created. When creators requestClaimMilestone they upload evidence they have completed the milestone. creators should be blocked from uploading any additional evidence so as to not deceive the donors.
- implement kleros token registry to only allow authorized tokens when declaring crowdfundToken when creaing a project
- implement project registry to remove projects when a projects specifications violate specific guidelines such as doing illegal things.