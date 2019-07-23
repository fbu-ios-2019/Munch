//
//  DecisionsViewController.m
//  Decider
//
//  Created by marialepestana on 7/19/19.
//  Copyright © 2019 kchan23. All rights reserved.
//

#import "DecisionsViewController.h"
#import "Routes.h"
#import "SwipeViewController.h"
#import "CityCell.h"
#import "MKDropdownMenu.h"

@interface DecisionsViewController () <UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, MKDropdownMenuDataSource, MKDropdownMenuDelegate>

@property (strong, nonatomic) NSArray *restaurants;

    // Categories
// Picker view for category
@property (weak, nonatomic) IBOutlet UIPickerView *categoryPicker;
// Array with all the categories passed to the picker
@property (strong, nonatomic) NSMutableArray *categories;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;

// Location
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, nonatomic) CLPlacemark *placemark;
    // Search bar
@property (weak, nonatomic) IBOutlet UITableView *locationsTableView;
@property (strong, nonatomic) NSArray *cities;
@property (strong, nonatomic) NSArray *filteredData;
@property (weak, nonatomic) IBOutlet UISearchBar *locationsSearchBar;
@property (weak, nonatomic) IBOutlet UILabel *selectedCategoryLabel;

@end


@implementation DecisionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

        // Delegates
    // Category delegates
    self.categoryPicker.delegate = self;
    self.categoryPicker.dataSource = self;
    
    // Location delegates
    self.locationManager = [[CLLocationManager alloc] init];
    self.geocoder = [[CLGeocoder alloc] init];
    
    // Table view delegates
    self.locationsTableView.delegate = self;
    self.locationsTableView.dataSource = self;
    
    // Search bar delegates
    self.locationsSearchBar.delegate = self;
    
    // Hide category picker
    self.categoryPicker.hidden = YES;
    [self.locationsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    // self.locationsTableView.hidden = YES;
    
    // Fetch information
    [self fetchRestaurants];
    [self fetchCategories];
    [self fetchLocations];
    
    // Dropdown menu
    MKDropdownMenu *dropdownMenu = [[MKDropdownMenu alloc] initWithFrame:CGRectMake(48, 53, 320, 44)];
    dropdownMenu.dataSource = self;
    dropdownMenu.delegate = self;
    [self.view addSubview:dropdownMenu];
    
    // Change category text field to what the user selected on the category picker
    // self.categoryTextField.inputView = picker
    self.selectedCategoryLabel.text =  self.categories[dropdownMenu.selectedComponent];
}


// Function that fetches restaurants from database
- (void)fetchRestaurants {
    NSURLSessionDataTask *task = [Routes fetchRestaurantsOfType:@"all" nearLocation:@"Sunnyvale" offset:0 count:20 completionHandler:^(NSData * _Nonnull data, NSURLResponse * _Nonnull response, NSError * _Nonnull error) {
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            NSArray *results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            NSLog(@"%@", results);
            self.restaurants = results;
        }
        
    }];
    if (!task) {
        NSLog(@"There was a network error");
    }
}


// Function that fetches locations for the locations search bar
- (void)fetchLocations {
    NSURLSessionDataTask *locationTask = [Routes fetchLocations:^(NSData * _Nonnull data, NSURLResponse * _Nonnull response, NSError * _Nonnull error) {
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            // NSLog(@"%@", results);
            self.cities = [results objectForKey:@"results"];
            self.filteredData = self.cities;
        }
        
    }];
    if (!locationTask) {
        NSLog(@"There was a network error");
    }
}


// Function that fetches categories from database
-(void)fetchCategories {
    NSURLSessionDataTask *categoryTask = [Routes fetchCategories:^(NSData * _Nonnull data, NSURLResponse * _Nonnull response, NSError * _Nonnull error) {
        if (error != nil) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            NSDictionary *results = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            // NSLog(@"%@", results);
            self.categories = [results objectForKey:@"results"];
            // NSLog(@"%@", self.categories);
        }
        
    }];
    if (!categoryTask) {
        NSLog(@"There was a network error");
    }
}

//- (IBAction)didTapScreen:(id)sender {
//    [self.view endEditing:YES];
//    self.categoryPicker.hidden = YES;
//}

- (IBAction)didTapCancel:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Navigation

// Function to prepare before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"swipeSegue"]) {
        // Get the new view controller using
        SwipeViewController *swipeViewController = [segue destinationViewController];
        // Pass restaurants to the next view controller
        swipeViewController.restaurants = self.restaurants;
    }
}

// Category functions start


- (IBAction)didTapDropdown:(id)sender {
    self.categoryPicker.hidden = NO;
}


// Protocol method that returns the number of columns (per row)
- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    // Hard coded number of categories we want to display
    return 1;
}


// Protocol method that returns the number of rows
- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
     // return self.categories.count;
    return 20;
}


// Protocol mehtod that returns the data to display for the row and column that's being passed
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.categories[row];
}


// Protocol method to save the user's selection
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.category = self.categories[row];
    NSLog(@"User selected %@", self.categories[row]);
    
    self.categoryTextField.text = self.categories[row];
    
}
// Category functions end


// Location functions start
- (IBAction)getCurrentLocation:(id)sender {
    [self.locationManager requestAlwaysAuthorization];
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services are not enabled");
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSLog(@"didFailWithError: %@", error);
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
        message:@"Failed to Get Your Location."
        preferredStyle:(UIAlertControllerStyleAlert)];
    // create an error action
    UIAlertAction *errorAction = [UIAlertAction actionWithTitle:@"OK"
        style:UIAlertActionStyleCancel
        handler:^(UIAlertAction * _Nonnull action) {
        // handle try again response here. Doing nothing will dismiss the view.
         }];
    
    // add the error action to the alertController
    [alert addAction:errorAction];
    
    [self presentViewController:alert animated:YES completion:^{
        // optional code for what happens after the alert controller has finished presenting
    }];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = [locations lastObject];
    //NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        // self.longitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        // self.latitudeLabel.text = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
    
    // Reverse Geocoding
    NSLog(@"Resolving the Address");
    [self.geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if(error == nil && [placemarks count] > 0) {
            self.placemark = [placemarks lastObject];
            self.location = [NSString stringWithFormat:@"%@ %@\n%@ %@\n%@\n%@",
                                      self.placemark.subThoroughfare, self.placemark.thoroughfare,
                                      self.placemark.postalCode, self.placemark.locality,
                                      self.placemark.administrativeArea,
                                      self.placemark.country];
        }
        else {
            NSLog(@"%@", error.debugDescription);
        }
    }];
}


    // Search bar functions begin
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    CityCell *cell = [self.locationsTableView dequeueReusableCellWithIdentifier:@"CityCell" forIndexPath:indexPath];
    
    NSString *city;
    
    if (self.filteredData != nil) {
        city = self.filteredData[indexPath.row];
    } else {
        city = self.cities[indexPath.row];
    }
    
    cell.cityLabel.text = city;
    
    return cell;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredData.count;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.locationsTableView.hidden = NO;
    if (searchText.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSString *evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject containsString:searchText];
        }];
        self.filteredData = [self.cities filteredArrayUsingPredicate:predicate];
        
        NSLog(@"%@", self.filteredData);
        
    }
    else {
        self.filteredData = self.cities;
    }
    
    [self.locationsTableView reloadData];
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.locationsSearchBar.showsCancelButton = YES;
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.locationsSearchBar.showsCancelButton = NO;
    self.locationsTableView.hidden = NO;
    self.locationsSearchBar.text = @"";
    [self.locationsSearchBar resignFirstResponder];
}
    // Search bar functions end
// Location functions end

- (NSInteger)dropdownMenu:(nonnull MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component {
    return 20;
    // return self.categories.count;
}

- (NSInteger)numberOfComponentsInDropdownMenu:(nonnull MKDropdownMenu *)dropdownMenu {
    return 1;
}

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForComponent:(NSInteger)component {
    self.selectedCategoryLabel.text = @"Category";
    return @"";
    
}

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.categories[row];
}

- (void)dropdownMenu:(MKDropdownMenu *)dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedCategoryLabel.text = self.categories[row];
    self.category = self.categories[row];
    [dropdownMenu closeAllComponentsAnimated:YES];
}

@end