//
//  SendGenericViewController.m
//  Ripple
//
//  Created by Kevin Johnson on 7/23/13.
//  Copyright (c) 2013 OpenCoin Inc. All rights reserved.
//

#import "SendGenericViewController.h"
#import "RippleJSManager.h"
#import "RippleJSManager+SendTransaction.h"
#import "RPContact.h"
#import "SendAmountViewController.h"
#import "RPTransaction.h"
#import "ZBarSDK.h"
#import "RPNewTransaction.h"
#import "SVProgressHUD.h"

@interface SendGenericViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, ZBarReaderDelegate> {
    NSArray * contacts;
}

@property (weak, nonatomic) IBOutlet UITableView * tableView;
@property (weak, nonatomic) IBOutlet UILabel * labelTitle;

@end

@implementation SendGenericViewController

-(void)startQRReader
{
    // ADD: present a barcode reader that scans from the camera feed
    ZBarReaderViewController *reader = [ZBarReaderViewController new];
    reader.readerDelegate = self;
    reader.supportedOrientationsMask = ZBarOrientationMaskAll;
    
    ZBarImageScanner *scanner = reader.scanner;
    // TODO: (optional) additional reader configuration here
    
    // EXAMPLE: disable rarely used I2/5 to improve performance
    [scanner setSymbology: ZBAR_I25
                   config: ZBAR_CFG_ENABLE
                       to: 0];
    
    // present and release the controller
    [self presentViewController:reader animated:YES completion:^{
        
    }];
}

- (void) imagePickerController: (UIImagePickerController*) reader
 didFinishPickingMediaWithInfo: (NSDictionary*) info
{
    // ADD: get the decode results
    id<NSFastEnumeration> results =
    [info objectForKey: ZBarReaderControllerResults];
    ZBarSymbol *symbol = nil;
    for(symbol in results)
        // EXAMPLE: just grab the first barcode
        break;
    
    [self checkValidAccount:symbol.data];
        
    // EXAMPLE: do something useful with the barcode data
    //resultText.text = symbol.data;
    
    // EXAMPLE: do something useful with the barcode image
    //resultImage.image =
    //[info objectForKey: UIImagePickerControllerOriginalImage];
    
    // ADD: dismiss the controller (NB dismiss from the *reader*!)
    [reader dismissViewControllerAnimated:YES completion:^{
        
    }];
    //[reader dismissModalViewControllerAnimated: YES];
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Next"]) {
        SendAmountViewController * view = [segue destinationViewController];
        view.transaction = self.transaction;
    }
}

-(void)checkValidAccount:(NSString*)account
{
    [SVProgressHUD showWithStatus:@"Validating address" maskType:SVProgressHUDMaskTypeGradient];
    [[RippleJSManager shared] wrapperIsValidAccount:account withBlock:^(NSError *error) {
        if (!error) {
            [SVProgressHUD dismiss];
            self.transaction.Destination = account;
            self.transaction.Destination_name = nil;
            
            [self performSegueWithIdentifier:@"Next" sender:nil];
        }
        else {
            [SVProgressHUD showErrorWithStatus:@"Invalid account"];
        }
    }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (textField.text.length > 0) {
        [self checkValidAccount:textField.text];
    }
    
    return YES;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    }
    else {
        return contacts.count;
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell;
    
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            cell.textLabel.text = @"QR Code";
            cell.detailTextLabel.text = nil;
        }
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"custom"];
        }
    }
    else {
        RPContact * contact = [contacts objectAtIndex:indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        cell.textLabel.text = contact.name;
        cell.detailTextLabel.text = contact.address;
    }
        
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // QR Code
            [self startQRReader];
        }
        else {
            // Custom address
        }
    }
    else {
        RPContact * contact = [contacts objectAtIndex:indexPath.row];
        self.transaction.Destination = contact.address;
        self.transaction.Destination_name = contact.name;
        [self performSegueWithIdentifier:@"Next" sender:nil];
    }
    
}

-(IBAction)buttonBack:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)refreshContacts
{
    contacts = [[RippleJSManager shared] rippleContacts];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    [self refreshContacts];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    self.labelTitle.text = [NSString stringWithFormat:@"Send %@", self.transaction.Currency];
}

-(void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshContacts) name:kNotificationUpdatedContacts object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationUpdatedContacts object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end