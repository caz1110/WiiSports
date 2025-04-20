# Wii Sports
*Wii Sports* is a team for Dr. Kaputa's Embedded Systems Design II class for the Spring 2025 semester at RIT. 

## Introduction + Switch From BitBucket
We plan to make our tennis tracker inspired by *Wii Sports*, hence the name! Initially, we planned to use *BitBucket* due to its seamless interaction with Jira, which we are using for team organization, but decided to switch to *GitHub* due to the **lower bar of learning** associated with it. We also decided on the switch because we were having issues that ate up more time than it was worth while using BitBucket. 

## Team Details
Each teammate in this team of seven has their own major role, alongside responsibilities, and potentially subroles. Our initial outline for roles is as follows, but subject to change by the end of this project, and will be updated to reflect that as work is completed. 

 - **Sumner, Jonathan** | @JRSumner1 | JRS1088
	 - Project and Python Lead
 - **Zamopra, Chris** | @caz1110 | CAZ1110
	 - FPGA Image Processing Lead
 - **Hong, Ryan** | @Beolida | RSH4342
	 - Systems Integration Lead
 - **DuBois, Rachel** | @roqqyroad | RJD5748
	 - QA & Version Control Lead
 - **Aquino, Argenis** | @crasher122 |  AA7863
	 - Blender Environment Lead
 - **Garcia, Hector** | @Alucarpinx | HIG9035
	 - Accuracy and Analytics Co-lead
 - **Delgadillo-Perez, David** | @ | DAD4043
	 - Accuracy and Analytics Co-lead

# Help Cloning Repository
To clone the repository (where we store all the code for this project, alongside do version control), you have a few options on how to do it. To clone, push, and pull it is easiest to do it through Visual Studio Code (the blue one, not the purple one). 

Below is a list of requirements before you get started: 
- Installed Visual Studio Code 
- Installed Git
- Logged into GitHub
- Member of the Wii Sports Organization on GitHub

If you do not have these requirements met and need help, DM Rachel on Discord. 
If you have already used Visual Studio Code, you will have to create a new window before you can follow the same steps (File > New Window)

The steps to clone the repository are below:

1. Click the "Source Control" icon in the left menu (Ctrl + Shift + G)
2. Click "Clone Repository"
3. Click "Clone from GitHub"
4. Wait for the list to populate. It will take a second depending on how many repositories you are a part of 
5. Click the repository that is titled "WiiSportsESD2/WiiSports"
6. Choose a location to save the repository and click "Select as Repository Destination"
7. It will download the repository to the selected location, which may take a second depending on how long we have been working. 
8. Click "Open in New Window"

You have now successfully cloned the repository! 
When you open Visual Studio Code, it will usually open at the location you were last at, which will likely be this repo. 
If it is not, you can see recent repositories by going to File > Open Recent > LOCAL REPO LOCATION AND NAME 
If you need further help cloning the repository, DM Rachel on Discord. I can either make a time to walk through it with you or help figure out what the issue you are experiencing is.  

# Branch Creation Through Jira
To maintain proper workflow and traceability, we'll create branches directly linked to Jira issues. Follow these steps:

1. Navigate to your assigned Jira issue
2. In the issue details, locate the "Create branch" button (usually near the top right)
3. Select "GitHub" as the repository source
4. Choose the base branch (typically `main` or `dev`)
5. The branch name will auto-generate based on the issue key (e.g., `JIRA-123-feature-description`)
6. Click "Create branch"
7. The branch will now be available in GitHub and your local repository after pulling

Alternatively, you can manually create a branch following the naming convention:
`<Jira-issue-key>-<short-description>` (e.g., `WS-45-implement-sensor-calibration`)

# Help Creating a Branch 
We are going to be using branches to avoid creating as many merge conflicts as possible and ensure that we can keep working in a smooth fashion. The branches system allows us to also ensure that no one is able to overwrite someone else's code (or at least much less likely to do so) if you forgot to push or pull. 

To create a branch in Visual Studio Code:

1. Click on the current branch name in the bottom left corner
2. Select "Create new branch"
3. Enter your branch name following the Jira naming convention
4. Select the base branch (usually `main`)
5. Make your changes and commit them to this branch
6. Push the branch to GitHub (see Pushing/Pulling section below)

If you need help with creating a branch in the repository, DM Rachel on Discord. 

# Creating Pull Requests
When your feature/bugfix is complete and tested:

1. Push all your changes to your branch
2. Navigate to the GitHub repository
3. Click on "Pull requests" > "New pull request"
4. Select your branch as the compare branch and `main` (or appropriate target) as the base branch
5. Add a descriptive title including the Jira issue key (e.g., "[WS-123] Implement motion detection")
6. In the description:
   - Reference the Jira issue (e.g., "Closes WS-123" or "Related to WS-456")
   - Describe changes made
   - List any testing performed
   - Note any dependencies
7. Request reviewers (typically your team leads)
8. Assign the PR to yourself
9. Link the Jira issue in the development panel
10. Click "Create pull request"

After approval:
- A team lead will merge your PR
- Delete the feature branch (unless specified otherwise)
- The Jira issue will automatically transition if you used "Closes" in the description

# Help Pushing and Pulling to & from Repository
For pushing and pulling, it will be easiest to do it through Visual Studio Code. The steps to do so are below. 
1. Click the refresh button in the bottom left next to your current branch name. 
2. If there is a down arrow, you must pull. 
3. Click the down arrow to pull. 
4. Wait until all updates are pulled down. 
5. After the updates are pulled, navigate to the Source Control menu (Ctrl + Shift + G)
6. In the top menu, you can see any changes you have made since your last commit. 
7. You can either add all the changes by hovering over the changes text, then clicking the plus that shows up; OR by clicking the plus that shows up next to the specific files you want to add. 
8. You can also subtract files if you commit them by accident. 
9. Once you have staged the changes you made that you want to commit, write a message that describes what you changed or did where it says Message (Ctrl + Enter). 
10. Click Commit to commit your changes. 
11. There will now be an up arrow next to the refresh button. 
12. Click it to push your changes to GitHub. If you do not do this, your changes will not show up for the rest of us. 

If you need help with pushing or pulling to or from the repository, DM Rachel on Discord. 
After pulling and pushing, you should be up to date with the latest changes.

# Best Practices
- Always pull before starting work
- Create a new branch for each feature/bugfix
- Keep branches focused on a single task
- Commit often with descriptive messages
- Push your work at the end of each session
- Create PRs early for feedback on WIP (mark as draft)
- Resolve merge conflicts promptly
- Delete merged branches to keep the repo clean

Remember to update your Jira issues with progress and link all commits/PRs to the relevant issues.