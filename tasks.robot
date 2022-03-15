*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download the orders csv file
    Read csv as a table and return the result
    Open the robot order website
    Order all robots
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    websites
    Open Available Browser    ${secret}[weburl]    browser_selection=firefox

Download the orders csv file
    ${secret}=    Get Secret    websites
    Download    ${secret}[csvfile]    overwrite=True
    
Read csv as a table and return the result
    ${orders}=    Read table from CSV    orders.csv
    [Return]    ${orders}

Build and order one robot
    [Arguments]    ${row}  
    Close the annoying modal
    Select From List By Value    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[1]/select    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    preview
    Wait Until Element Is Visible    robot-preview
    Click Button    order
    
    ${res}    Does Page Contain Element    css:div.alert.alert-danger
    IF    ${res} == True 
        Wait Until Keyword Succeeds    5 sec    0.5 sec    Click Button    order
    END
    
    Export receipt as a PDF    ${row}    
    Screenshot    filename=${OUTPUT_DIR}${/}screenshots/screenshot-${row}[Order number].png
    Embed the robot screenshot to the receipt PDF file    ${row}
    Click Button    order-another

Close the annoying modal
    Wait Until Page Contains Element    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]
    Click Element    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]

Export receipt as a PDF
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${receipt_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_results_html}    ${OUTPUT_DIR}${/}pdfs/receipt_result-${row}[Order number].pdf
    
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${row}
    ${files}=    Create List    ${OUTPUT_DIR}${/}screenshots/screenshot-${row}[Order number].png
    Open Pdf    ${OUTPUT_DIR}${/}pdfs/receipt_result-${row}[Order number].pdf
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}pdfs/receipt_result-${row}[Order number].pdf    append=True
    Close Pdf    ${OUTPUT_DIR}${/}pdfs/receipt_result-${row}[Order number].pdf

Order all robots
    ${orders}=    Read csv as a table and return the result
    FOR    ${row}    IN    @{orders}
        Build and order one robot    ${row}
    END

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}pdfs/    ${OUTPUT_DIR}${/}receipts_pdfs.zip