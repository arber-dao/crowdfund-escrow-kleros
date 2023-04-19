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
- add logic to allow projects to have no milestones, and any donations the project receives can be immediately withdrawn (no dispute resolution required)
- add the ability to create appeals. have to look into this, but it might be solely a front end thing. appeals will be created by the user interacting directly with the arbitrator contract (dispute kit) by calling fundAppeal(). Additionally they can withdraw fee when an appeal is won by calling withdrawFeesAndRewards(). This might cause confusion, since overpaid dispute creation fees, and any other withdrawls will go through FundMeCore. Hopefully if the client app handles this well, and with EIP-3074 or EIP-4337, we can batch transactions, then this shouldnt be too much of an issue.
- fix the fact that donors should only be able to withdraw % of their donations if the creator has already claimed some of the milestones. If someone donates, then the creator withdraws funds for 2 milestones, with still 2 remaining, and donors win a dispute, the donor should only receive a portion of their funds back depending on the % claimed, and (maybe) the point at which they deposited funds. having donors allowed to withdraw all their funds could cause a lack of liquidity in the project, which means the contract is broken.